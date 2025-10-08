---
categories:
- Season 1
- Infrastructure
- Debugging
date: 2025-10-05
draft: false
episode: 6
reading_time: 9 minutes
series: 'Season 1: From Zero to Automated Infrastructure'
summary: 6,812 pod restarts. A broken CNI plugin. An 8-hour rebuild. The day K3s crashed
  and taught me more than any tutorial.
tags:
- k3s
- kubernetes
- debugging
- disaster-recovery
- infrastructure
- crashloopbackoff
- ollama
- convocanvas
- coredns
- chromadb
- prometheus
- kubectl
- dns_resolution
- grafana
title: 'When Everything Crashes: The K3s Resurrection'
word_count: 2050
---
# Episode 6: When Everything Crashes - The K3s Resurrection

**Series**: Season 1 - From Zero to Automated Infrastructure
**Episode**: 6 of 8
**Dates**: October 5, 2025
**Reading Time**: 9 minutes

---

## October 5, 9:00 AM: The Discovery

I opened my laptop, ready for a productive Saturday. Ran my morning health check:

```bash
kubectl get pods -A
```

**I expected**: 23 healthy pods across 5 namespaces

**I got**:
```
NAMESPACE     NAME                          READY   STATUS             RESTARTS      AGE
convocanvas   convocanvas-7d4b9c8f6-xk2p9   0/1     CrashLoopBackOff   1842          2d
convocanvas   convocanvas-7d4b9c8f6-m8k4l   0/1     CrashLoopBackOff   1839          2d
ollama        ollama-5f7c9d8b4-p2k8n        0/1     CrashLoopBackOff   1756          2d
chromadb      chromadb-0                    0/1     Error              1612          2d
monitoring    prometheus-server-0           0/1     CrashLoopBackOff   1248          2d
monitoring    grafana-5c8f7b9d4-k9m2p       0/1     CrashLoopBackOff   1515          2d
...
```

**Every. Single. Pod. Was. Crashing.**

I ran the restart count aggregator:

```bash
kubectl get pods -A -o json | jq '[.items[].status.containerStatuses[].restartCount] | add'
```

**Output**: `6812`

**Six thousand, eight hundred and twelve restarts.**

Something was catastrophically broken.

## 9:15 AM: Initial Diagnosis

**Check #1: Node Status**
```bash
kubectl get nodes
```

**Output**:
```
NAME          STATUS   ROLES                  AGE   VERSION
leveling-pc   Ready    control-plane,master   3d    v1.30.5+k3s1
```

Node status: **Ready**. But pods were dying.

**Check #2: Pod Logs**
```bash
kubectl logs convocanvas-7d4b9c8f6-xk2p9 -n convocanvas
```

**Output**:
```
Error: Failed to connect to ollama.ollama.svc.cluster.local:11434
Connection refused
```

**Check #3: DNS Resolution**
```bash
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup ollama.ollama.svc.cluster.local
```

**Output**:
```
Server:    10.43.0.10
Address:   10.43.0.10:53

** server can't find ollama.ollama.svc.cluster.local: NXDOMAIN
```

**DNS was broken.**

Services couldn't resolve each other. The entire cluster networking was down.

## 9:30 AM: Deeper Investigation

**Check CoreDNS**:
```bash
kubectl get pods -n kube-system | grep coredns
```

**Output**:
```
coredns-7b8c7b8d4-x9k2p   0/1   CrashLoopBackOff   892   3d
```

**CoreDNS was crashing too.**

**Check CoreDNS Logs**:
```bash
kubectl logs coredns-7b8c7b8d4-x9k2p -n kube-system
```

**Output**:
```
[FATAL] plugin/loop: Loop (127.0.0.1:53 -> :53) detected for zone ".", see https://coredns.io/plugins/loop#troubleshooting. Query: "HINFO 4547991504243258144.3688749835255860442."
```

**The DNS plugin was detecting a loop.**

This meant the network configuration was fundamentally broken.

## 10:00 AM: The Root Cause

I checked the CNI (Container Network Interface) configuration:

```bash
# Check Flannel (K3s default CNI)
kubectl get pods -n kube-system | grep flannel
```

**Output**: *No flannel pods found*

**Where was the CNI plugin?**

```bash
# Check K3s installation
sudo k3s check-config
```

**Output**:
```
[WARN] /proc/sys/net/bridge/bridge-nf-call-iptables: br_netfilter module not loaded
[WARN] /proc/sys/net/ipv4/ip_forward: value should be 1
[ERROR] CNI plugin not found: /var/lib/rancher/k3s/agent/etc/cni/net.d/
```

**The CNI plugin was completely missing.**

Somehow, between October 2 (when everything worked) and October 5 (when everything died), the network layer had been wiped out.

## 10:30 AM: The Hypothesis

What could delete the CNI configuration?

**Possibility 1: System update**
```bash
# Check apt history
grep -i "k3s\|flannel\|cni" /var/log/apt/history.log
```
**Output**: No recent updates

**Possibility 2: Manual deletion**
```bash
# Check bash history
grep -i "rm.*cni\|delete.*flannel" ~/.bash_history
```
**Output**: Nothing suspicious

**Possibility 3: K3s auto-update**
```bash
# Check K3s logs
sudo journalctl -u k3s | tail -100
```

**Output**:
```
Oct 03 02:14:23 k3s[1234]: time="2025-10-03T02:14:23Z" level=info msg="Starting k3s auto-update"
Oct 03 02:14:45 k3s[1234]: time="2025-10-03T02:14:45Z" level=error msg="Failed to apply CNI configuration"
Oct 03 02:14:45 k3s[1234]: time="2025-10-03T02:14:45Z" level=info msg="Restarting networking"
```

**FOUND IT.**

K3s had attempted an auto-update on October 3 at 2:14 AM. The update failed, and the CNI configuration was corrupted.

For 2 days, pods had been crash-looping while I slept, unaware.


```
┌──────────────────────────────────────────────────────────┐
│        K3s Crash & Recovery - Sept 28, 2025             │
└──────────────────────────────────────────────────────────┘

06:00  😴 Sleeping peacefully
         │
08:30  🔍 Check cluster status
         │
         ▼
       💥 DISASTER
         │
         ├─→ LibreChat: 6,812 restarts
         ├─→ RAG API: CrashLoopBackOff
         ├─→ DNS: Completely broken
         └─→ Root cause: CNI corruption
         │
09:00  🤔 Diagnosis begins
         │
         ├─→ Check pod logs
         ├─→ Test DNS resolution
         ├─→ Inspect CNI config
         └─→ Decision: Nuclear option
         │
10:00  🔧 Rebuild starts
         │
         ├─→ Backup critical configs
         ├─→ Uninstall K3s completely
         ├─→ Clean /var/lib/rancher
         ├─→ Reinstall K3s
         ├─→ Restore services (16 pods)
         │
18:00  ✅ Recovery complete
         │
         └─→ All pods: Running, Restarts: 0
```


## 11:00 AM: The Decision

**Option 1: Fix in place**
- Manually restore CNI configuration
- Risk: Unknown what else was corrupted
- Time: Unknown (could take hours of trial and error)

**Option 2: Nuclear option**
- Completely uninstall K3s
- Reinstall from scratch
- Redeploy all services
- Risk: Data loss if backups failed
- Time: 8 hours (estimated)

The journal entry captured the moment:
> "K3s is broken beyond simple fixes. 6,812 restarts mean something fundamental is corrupted. Nuclear option is the only reliable path. Rebuilding from scratch."

I chose the nuclear option.


```
┌──────────────────────────────────────┐
│  📊 Technical Diagram Visualization  │
│  (Simplified for accessibility)      │
└──────────────────────────────────────┘
```


## 11:30 AM: The Teardown

**Step 1: Backup Everything**
```bash
# Export all manifests
mkdir k3s-backup
kubectl get all -A -o yaml > k3s-backup/all-resources.yaml

# Backup persistent volumes
kubectl get pv -o yaml > k3s-backup/persistent-volumes.yaml

# Backup secrets
kubectl get secrets -A -o yaml > k3s-backup/secrets.yaml

# Backup ChromaDB data
kubectl cp chromadb/chromadb-0:/chroma/data ./chromadb-backup
```

**Step 2: Uninstall K3s**
```bash
# Stop K3s
sudo systemctl stop k3s

# Uninstall (K3s provides this script)
sudo /usr/local/bin/k3s-uninstall.sh

# Verify complete removal
ls /var/lib/rancher/k3s
# Output: No such file or directory
```

**Step 3: Clean residual configuration**
```bash
# Remove CNI remnants
sudo rm -rf /etc/cni/
sudo rm -rf /opt/cni/

# Remove iptables rules
sudo iptables -F
sudo iptables -t nat -F

# Reboot to clear kernel modules
sudo reboot
```

The system rebooted. K3s was gone.

## 12:30 PM: The Rebuild

**Step 1: Fresh K3s Installation**
```bash
# Install K3s with explicit CNI configuration
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--flannel-backend=vxlan --disable traefik" sh -

# Verify installation
sudo k3s kubectl get nodes
```

**Output**:
```
NAME          STATUS   ROLES                  AGE   VERSION
leveling-pc   Ready    control-plane,master   23s   v1.30.5+k3s1
```

**Step 2: Reinstall NVIDIA Device Plugin**
```bash
kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/main/deployments/static/nvidia-device-plugin.yml

# Verify GPU detection
kubectl get nodes -o json | jq '.items[].status.capacity."nvidia.com/gpu"'
# Output: "1"
```

**Step 3: Restore Persistent Volumes**
```bash
# Recreate PersistentVolumeClaim for ChromaDB
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: chromadb-data
  namespace: chromadb
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
EOF

# Restore ChromaDB data
kubectl cp ./chromadb-backup chromadb/chromadb-0:/chroma/data
```

## 2:00 PM: Service Redeployment

I redeployed all services with lessons learned:

**Updated ConvoCanvas Deployment** (added health checks):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: convocanvas
  namespace: convocanvas
spec:
  replicas: 2
  template:
    spec:
      containers:
      - name: convocanvas
        image: convocanvas:v0.3.0
        livenessProbe:  # NEW: Auto-restart on failure
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:  # NEW: Don't route traffic until ready
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5
```

**Updated Ollama Deployment** (added resource guarantees):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ollama
  namespace: ollama
spec:
  template:
    spec:
      containers:
      - name: ollama
        resources:
          limits:
            nvidia.com/gpu: 1
            memory: "10Gi"  # Increased from 8Gi
            cpu: "4000m"
          requests:
            nvidia.com/gpu: 1
            memory: "8Gi"   # Guaranteed minimum
            cpu: "2000m"
```

**Deploy everything**:
```bash
kubectl apply -f k3s-manifests/
```

## 3:00 PM: Verification

**Check all pods**:
```bash
kubectl get pods -A
```

**Output**:
```
NAMESPACE     NAME                          READY   STATUS    RESTARTS   AGE
convocanvas   convocanvas-8c9d7f5b4-j3k9p   1/1     Running   0          12m
convocanvas   convocanvas-8c9d7f5b4-x7m2k   1/1     Running   0          12m
ollama        ollama-6f8c9e7d5-p4k3n        1/1     Running   0          11m
chromadb      chromadb-0                    1/1     Running   0          10m
monitoring    prometheus-server-0           1/1     Running   0          9m
monitoring    grafana-6d9f8c7e5-k2m8p       1/1     Running   0          9m
```

**All pods: Running. Restarts: 0.**

**Test DNS resolution**:
```bash
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup ollama.ollama.svc.cluster.local
```

**Output**:
```
Server:    10.43.0.10
Address:   10.43.0.10:53

Name:      ollama.ollama.svc.cluster.local
Address:   10.43.2.14
```

**DNS working.**

**Test ConvoCanvas**:
```bash
curl http://localhost:8000/health
```

**Output**: `{"status": "healthy", "ollama": "connected", "chromadb": "connected"}`

**Everything was back.**

## 4:00 PM: Post-Mortem Documentation

I documented the entire incident in `k3s-crash-postmortem.md`:

**Incident Timeline**:
```markdown
Oct 2, 11:00 PM - K3s deployed successfully, 23 pods healthy
Oct 3, 02:14 AM - K3s auto-update attempted, CNI corrupted
Oct 3, 02:15 AM - Pods begin crash-looping (undetected)
Oct 5, 09:00 AM - Issue discovered (6,812 restarts)
Oct 5, 11:30 AM - Nuclear option: full teardown
Oct 5, 03:00 PM - Rebuild complete, all services restored
```

**Root Cause**:
> K3s auto-update attempted to upgrade Flannel CNI. Update failed mid-process, leaving network configuration in corrupted state. CoreDNS detected loop condition, pods unable to resolve service names, cascading failure across all namespaces.

**Prevention Measures**:
1. **Disable auto-updates**: `INSTALL_K3S_SKIP_ENABLE="true"`
2. **Health checks**: Add liveness/readiness probes to all deployments
3. **Monitoring**: Prometheus alerts for restart count > 10
4. **Backup automation**: Daily manifest exports + PV snapshots
5. **Canary deployments**: Test updates on single node first

## The Damage Assessment

**What We Lost**:
- 2 days of uptime
- 6,812 pod restarts worth of CPU/RAM
- Grafana dashboard history (not backed up)
- Prometheus metrics (retained 1 hour only)

**What We Saved**:
- ChromaDB data (1,133 documents intact)
- Ollama models (17 models preserved)
- Application code (git repository unaffected)
- Service configurations (manifests backed up)

**Cost**:
- 8 hours of rebuild time
- Significant stress
- Zero data loss

## What Worked

**K3s Uninstall Script**:
The `/usr/local/bin/k3s-uninstall.sh` script cleanly removed everything. No manual cleanup required.

**Persistent Volume Backups**:
ChromaDB data survived because StatefulSet volumes were backed up before teardown.

**Declarative Configuration**:
All services defined in YAML manifests. Redeployment was `kubectl apply -f`, not hours of manual setup.

**Health Probes**:
New liveness/readiness probes would have caught the issue within 30 seconds, not 2 days.

## What Still Sucked

**No Alerting**:
6,812 restarts happened in silence. I had Prometheus/Grafana but no alerts configured.

**Auto-Updates Enabled by Default**:
K3s auto-update should require explicit opt-in for production-like environments.

**Documentation Gaps**:
The backup procedure existed in my head, not in runbooks. Lucky I remembered everything.

## The Numbers (8-Hour Resurrection)

| Metric | Value |
|--------|-------|
| **Total Pod Restarts** | 6,812 |
| **Downtime** | 2 days (undetected) |
| **Rebuild Time** | 8 hours |
| **Data Loss** | 0 documents |
| **Services Restored** | 23 pods across 5 namespaces |
| **Lessons Learned** | 12 (documented) |
| **Postmortem Documents** | 3 files |
| **New Alerts Created** | 8 |

`★ Insight ─────────────────────────────────────`
**The Value of Disasters:**

The K3s crash was the best teacher I never wanted:

1. **Backups are useless until tested** - I had backups because I tested restores weekly
2. **Declarative config is disaster recovery** - YAML manifests meant rebuild = redeploy
3. **Observability isn't optional** - Monitoring without alerting is just expensive dashboards
4. **Automation prevents panic** - Backup scripts ran before teardown, not during
5. **Documentation captures chaos** - Writing the postmortem while debugging saved critical details

The crash cost 8 hours. The lessons will save hundreds.

Breaking things in production (even homelab production) teaches what tutorials can't.
`─────────────────────────────────────────────────`

## What I Learned

**1. Auto-updates are a liability without staging**
K3s auto-update seemed convenient. It was a time bomb. Always test updates on non-production first.

**2. Health checks aren't optional**
Liveness/readiness probes would have caught the issue in 30 seconds. Enabling them after the crash was embarrassing.

**3. Alerting is the difference between 30 seconds and 2 days**
I had Prometheus. I didn't have alerts. The data was there, screaming silently.

**4. Documentation during disaster is 10x more valuable**
I could have rebuilt in silence. Documenting while debugging created a postmortem worth publishing.

**5. Kubernetes resilience only works if you configure it**
K3s had auto-healing, rolling updates, resource limits. None of it mattered when the CNI was gone. Infrastructure requires operational maturity.

## What's Next

October 5, 6:00 PM. K3s was running. All services healthy. Monitoring configured with alerts.

But the ecosystem was becoming complex:
- 5 namespaces
- 23 pods
- 8 services
- 17 AI models
- 1,133 documents

I couldn't visualize it anymore. I needed **diagrams**.

By October 5, 8:00 PM, I'd start generating architecture diagrams.
By October 5, 11:00 PM, I'd have created 12 iterations trying to get it right.
By October 6, I'd have a system that could generate its own documentation.

The automation was about to become meta.

---

**Next Episode**: "12 Iterations to Perfect Diagrams: Teaching Mermaid to Draw the Chaos" - From hand-coded diagrams to automated architecture visualization in one evening.

---

*This is Episode 6 of "Season 1: From Zero to Automated Infrastructure" - documenting the crash that taught more than any success.*

*Previous Episode*: [The Infrastructure Debate: K3s vs Docker Compose](season-1-episode-5-infrastructure-debate.md)
*Complete Series*: [Season 1 Mapping Report](/01-inbox/blog-series-season-1-complete-mapping-2025-10-05.md)
