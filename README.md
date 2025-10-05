# Ryan Duffy's AI Infrastructure Blog

Technical deep-dives into AI infrastructure, local LLM performance tuning, and automation engineering.

**Live Site**: [blog.rduffy.uk](https://blog.rduffy.uk)

## Tech Stack

- **Generator**: Hugo (v0.146+)
- **Theme**: PaperMod
- **Diagrams**: Mermaid.js (client-side rendering)
- **Hosting**: GitHub Pages / Netlify / Cloudflare Pages
- **Dynamic Content**: Python diagram generators

## Build Pipeline

This blog uses a **two-stage build process**:

### Stage 1: Generate Dynamic Diagrams (Python)
```bash
# Run Python scripts to generate architecture/dataflow diagrams
python3 render_mermaid_architecture.py
python3 render_dataflow_diagram.py
python3 render_ecosystem_diagram.py
```

Generated diagrams are saved to `content/diagrams/` for Hugo to process.

### Stage 2: Hugo Build
```bash
# Build static site from markdown + generated content
hugo --cleanDestinationDir
```

### Automated Build (Recommended)
Use the included build script that runs both stages:

```bash
./build.sh
```

**What it does**:
1. ✅ Runs all Python diagram generators
2. ✅ Copies generated diagrams to `content/diagrams/`
3. ✅ Builds Hugo site with all content
4. ✅ Handles missing Python scripts gracefully (continues on errors)

## Local Development

### Preview Site Locally
```bash
./build.sh        # Generate diagrams + build site
hugo server       # Start dev server at http://localhost:1313
```

### Quick Rebuild (No Diagram Generation)
```bash
hugo --cleanDestinationDir
hugo server
```

## Content Structure

```
content/
├── posts/              # Blog posts (Season 1 episodes, technical guides)
├── diagrams/           # Auto-generated architecture diagrams (Python output)
└── about.md            # About page
```

## Mermaid Diagram Support

Diagrams render **client-side** with Mermaid.js:

### Static Diagrams (Markdown)
Write Mermaid directly in markdown:

\`\`\`mermaid
graph TD
    A[Start] --> B[Process]
    B --> C[End]
\`\`\`

### Dynamic Diagrams (Python-Generated)
Python scripts read YAML data and generate Mermaid markdown:

```python
# render_mermaid_architecture.py
# Reads: infrastructure-complete-with-flows.yaml
# Outputs: content/diagrams/Architecture-v0.1.0-mermaid-arch.md
```

Both types render as SVG in the browser via `extend_head.html` JavaScript.

## Deployment

### Automated Deployment
Push to GitHub triggers automatic rebuild:

```bash
./build.sh                  # Generate diagrams + build
git add .
git commit -m "Add Episode 4"
git push origin master      # Auto-deploys
```

### Manual Deployment
If using manual hosting, upload the `public/` folder after running `./build.sh`.

## Configuration

### Hugo Config ([hugo.toml](hugo.toml))
- **baseURL**: `https://blog.rduffy.uk/`
- **Theme**: PaperMod
- **Mermaid**: Custom JavaScript in `layouts/partials/extend_head.html`

### Python Diagram Generators
Located in project root (parent directory):
- `render_mermaid_architecture.py` - System architecture diagrams
- `render_dataflow_diagram.py` - Data flow diagrams
- `render_ecosystem_diagram.py` - Ecosystem overview

## Troubleshooting

### Diagrams Not Rendering

#### **Most Common Issue: Cloudflare Rocket Loader**

If diagrams work locally (`hugo server`) but fail in production, Cloudflare's Rocket Loader is likely breaking ES module imports.

**Symptoms**:
- ✅ Local development: Diagrams render perfectly
- ❌ Production: Diagrams show as plain text
- Console error: `Failed to load module script` or `Unexpected token 'import'`

**Fix Option 1 - Disable Rocket Loader (Recommended)**:
1. Log into Cloudflare Dashboard
2. Go to **Speed** → **Optimization**
3. Scroll to **Rocket Loader** and toggle **OFF**
4. **Purge Cache**: Caching → Configuration → Purge Everything
5. Wait 2-3 minutes for changes to propagate

**Fix Option 2 - Script Already Has Bypass**:
Our Mermaid script includes `data-cfasync="false"` which tells Rocket Loader to skip this script. If Rocket Loader is still interfering, use Fix Option 1.

**Verify Fix**:
```bash
# Check if Rocket Loader is active on your site
curl -I https://blog.rduffy.uk | grep -i "cf-"
```

#### **Other Diagram Issues**

1. **Check browser console** for JavaScript errors
2. **Verify Mermaid CDN** is accessible:
   ```bash
   curl -I https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs
   ```
3. **Inspect HTML source** - diagrams should be `<pre class="mermaid">` (not `<pre><code>`)
4. **Test in incognito mode** to rule out browser extension interference
5. **Check Content Security Policy** - ensure `script-src` allows `cdn.jsdelivr.net`

### Build Fails
```bash
# Check Hugo version
hugo version  # Should be v0.146+

# Rebuild from scratch
rm -rf public/
./build.sh
```

### Python Diagram Errors
```bash
# Run diagrams manually to see errors
cd ..  # Go to project root
python3 render_mermaid_architecture.py
```

Missing YAML files will cause errors but won't break the build (pipeline continues).

## Contributing

This is a personal blog, but if you spot typos or technical errors:
1. Open an issue: [github.com/rduffyuk/blog/issues](https://github.com/rduffyuk/blog/issues)
2. Or submit a PR with fixes

## License

- **Blog content**: © 2025 Ryan Duffy (All rights reserved)
- **Code snippets**: MIT License (feel free to use)
- **Hugo theme**: PaperMod (MIT License)

---

**Generated with Hugo + PaperMod | Diagrams by Mermaid.js | Hosted on GitHub**
