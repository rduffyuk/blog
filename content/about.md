---
title: "About"
url: "/about/"
ShowReadingTime: false
ShowShareButtons: false
ShowPostNavLinks: false
ShowBreadCrumbs: false
ShowCodeCopyButtons: false
ShowWordCount: false
ShowRssButtonInSectionTermList: false
disableShare: true
---

# About This Blog

Hi, I'm **Ryan Duffy**, and this is my digital garden where I document my journey building a production-grade AI infrastructure on consumer hardware.

## What I'm Building

I run a complete local AI stack on an RTX 4080:
- **11 local LLM models** via Ollama (Mistral, Qwen, DeepSeek)
- **vLLM server** for high-performance inference
- **Kubernetes observability** (Jaeger, OpenTelemetry, Kafka)
- **ChromaDB semantic search** with 504 indexed documents
- **Automated workflows** using Prefect

## Why This Blog?

Most AI content is either:
- Theoretical tutorials that don't show real performance
- Enterprise solutions requiring $10k/month budgets
- Hobby projects that don't scale

**I'm bridging the gap** - showing how to build professional AI infrastructure on a £1,500 GPU that delivers production-quality results.

## What You'll Learn

- **Real benchmarks**: Actual tokens/sec, VRAM usage, latency measurements
- **Configuration deep-dives**: The settings that actually matter
- **Automation patterns**: How to build systems that maintain themselves
- **Cost optimization**: Getting $0/month inference with enterprise quality

## My Stack

**Hardware**: RTX 4080 (16GB), i9-13900KF, 62GB RAM
**Software**: Ubuntu 22.04, K3s, Ollama 0.12.3, vLLM, PyTorch
**Workflow**: Obsidian vault → Prefect automation → ChromaDB indexing
**Philosophy**: Local-first, automation-driven, measurably fast

## Current Projects

### ConvoCanvas (Season 1 - September 2025)
A system that transforms AI conversations into publishable content:
- Automatically extracts insights from Claude/ChatGPT conversations
- Organizes knowledge into searchable Obsidian vault structure
- Generates blog posts with embedded Mermaid diagrams
- **Status**: Publishing Season 1 (8 episodes covering 25-day journey)

### Neural Vault
Semantic search across 1000+ documentation files:
- ChromaDB indexing with mxbai-embed-large embeddings
- Dual-layer caching (gather + action phases)
- MCP integration for Claude Code
- Sub-second search with smart routing

### K3s Observability Stack
Full distributed tracing on single-node cluster:
- Jaeger + OpenTelemetry for request tracing
- Kafka streaming pipeline
- Prometheus + Grafana metrics
- MongoDB with Percona operator

## What Are "Tags" on This Blog?

**Tags are topic labels** that help you explore related content. Each tag represents a technology, concept, or project I'm working with.

**How to use tags**:
- Click any tag on a blog post (e.g., [#Ollama](/tags/ollama/), [#ChromaDB](/tags/chromadb/))
- See all posts related to that topic
- Follow my journey with specific technologies chronologically

**Popular tags**:
- [#ConvoCanvas](/tags/convocanvas/) - Automated blog publishing project
- [#Ollama](/tags/ollama/) - Local LLM inference
- [#K3s](/tags/k3s/) - Kubernetes observability
- [#ChromaDB](/tags/chromadb/) - Semantic search
- [#vLLM](/tags/vllm/) - High-performance LLM serving

Tags let you **skip the chronological timeline** and dive straight into topics you care about.

## Connect

- **GitHub**: [github.com/rduffyuk](https://github.com/rduffyuk) - Public code & configs
- **RSS**: [Subscribe to feed](/index.xml) - New posts delivered weekly

## Philosophy

**Build > Buy**: If it can run locally, I'll make it work
**Document > Ship**: Learning in public beats silent shipping
**Honest > Impressive**: Real limitations beat fake unlimited claims

---

*Last updated: October 5, 2025*
*Generated with Hugo + PaperMod | Hosted on GitHub Pages | Written in Obsidian*
