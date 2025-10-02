---
title: "Welcome to My AI Infrastructure Journey"
date: 2025-10-02
draft: false
tags: ["introduction", "ai", "infrastructure", "rtx-4080"]
categories: ["Meta"]
ShowToc: true
TocOpen: false
weight: 1
---

## Why This Blog Exists

After months of building a local AI infrastructure stack, I kept encountering the same problem: **most AI content online is either too theoretical or too enterprise-focused**.

I wanted to share what actually works when you're running LLMs on a consumer GPU - the real performance numbers, the gotchas, the configuration tweaks that made the difference.

## What I've Built So Far

Here's my current setup (as of October 2025):

### Hardware
- **GPU**: NVIDIA RTX 4080 (16GB VRAM)
- **CPU**: Intel i9-13900KF
- **RAM**: 62GB DDR5
- **Storage**: 2TB NVMe SSD

### Software Stack
- **LLM Runtime**: Ollama 0.12.3 (11 models)
- **High-Performance Inference**: vLLM 0.10.2
- **Knowledge Base**: Obsidian vault with 504 indexed documents
- **Semantic Search**: ChromaDB with mxbai-embed-large-v1
- **Automation**: Prefect workflows (journal generation, vault indexing)
- **Observability**: Jaeger + OpenTelemetry + Kafka on K3s

### Performance Achievements
- **24x faster inference** with vLLM vs standard serving
- **32-600% speed improvement** after Ollama 0.12.3 upgrade
- **Zero-cost operation** for unlimited queries
- **< 1 second** semantic search across 500+ documents
- **Automated maintenance** with Prefect flows every 30 minutes

## What You'll Learn Here

I'll be covering:

### 🚀 Performance Tuning
- vLLM configuration for consumer GPUs
- Ollama optimization strategies
- CUDA memory management
- Model quantization trade-offs

### 🏗️ Architecture Patterns
- Building automation pipelines with Prefect
- Semantic search with ChromaDB
- Kubernetes observability on K3s
- Integration patterns for local LLMs

### 📊 Real Benchmarks
- Tokens/second across different models
- VRAM usage patterns
- Latency measurements
- Quality vs speed trade-offs

### 🛠️ Practical How-Tos
- Setting up specific tools
- Debugging common issues
- Configuration that actually matters
- Cost optimization strategies

## My Philosophy

**Local-first, automation-driven, measurably fast.**

I believe in:
- Building systems that maintain themselves
- Measuring everything that matters
- Sharing real data, not marketing claims
- Making professional AI accessible

## Coming Soon

I'm working on deep-dives into:
- My Phase 4 automation architecture
- vLLM 0.10.2 setup guide for RTX 4080
- Obsidian → ChromaDB indexing pipeline
- Multi-agent routing patterns

## Let's Connect

Follow along as I document this journey. Subscribe via RSS, or check out my [GitHub](https://github.com/rduffyuk) for the code behind these systems.

---

*This blog is generated from my Obsidian vault using an automated Hugo + Cloudflare Pages pipeline. Meta, right?*
