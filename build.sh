#!/bin/bash
# Blog Build Pipeline - Pre-build + Hugo
# Runs Python diagram generators, then builds Hugo site

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Blog Build Pipeline"
echo "===================="
echo "Project root: $PROJECT_ROOT"
echo "Blog dir: $SCRIPT_DIR"
echo ""

# Step 1: Run Python diagram generators (if they exist)
echo "📊 Step 1: Generate dynamic diagrams..."
cd "$PROJECT_ROOT"

# Check if Python diagram scripts exist
DIAGRAM_SCRIPTS=(
    "render_mermaid_architecture.py"
    "render_dataflow_diagram.py"
    "render_ecosystem_diagram.py"
)

DIAGRAMS_GENERATED=0

for script in "${DIAGRAM_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo "  ▶️  Running $script..."
        python3 "$script" 2>&1 | grep -E "(Saved:|Error:|components)" || true
        DIAGRAMS_GENERATED=$((DIAGRAMS_GENERATED + 1))
    fi
done

if [ $DIAGRAMS_GENERATED -eq 0 ]; then
    echo "  ℹ️  No diagram generators found (optional)"
else
    echo "  ✅ Generated diagrams from $DIAGRAMS_GENERATED scripts"
fi

echo ""

# Step 2: Copy generated diagrams to Hugo content (if needed)
echo "📁 Step 2: Copy generated content to Hugo..."

# Check if there are generated diagrams in obsidian-vault/01-Inbox
INBOX_PATH="$PROJECT_ROOT/obsidian-vault/01-Inbox"
HUGO_CONTENT="$SCRIPT_DIR/content/diagrams"

if [ -d "$INBOX_PATH" ]; then
    # Create diagrams directory if it doesn't exist
    mkdir -p "$HUGO_CONTENT"

    # Copy architecture diagrams (auto-generated files)
    COPIED=0
    for file in "$INBOX_PATH"/Architecture-v*-mermaid*.md; do
        if [ -f "$file" ]; then
            cp "$file" "$HUGO_CONTENT/"
            COPIED=$((COPIED + 1))
        fi
    done

    if [ $COPIED -gt 0 ]; then
        echo "  ✅ Copied $COPIED generated diagrams"
    else
        echo "  ℹ️  No generated diagrams to copy"
    fi
else
    echo "  ℹ️  Obsidian vault not found (optional)"
fi

echo ""

# Step 3: Pre-render Mermaid diagrams to SVG
echo "🎨 Step 3: Pre-rendering Mermaid diagrams..."
cd "$SCRIPT_DIR"

# Pull Mermaid CLI Docker image if not present
if ! docker image inspect minlag/mermaid-cli:10.8.0 &> /dev/null; then
    echo "  📥 Pulling Mermaid CLI Docker image (one-time download)..."
    docker pull minlag/mermaid-cli:10.8.0
fi

# Find all markdown files with Mermaid blocks and convert them
echo "  🔍 Scanning for Mermaid diagrams..."
DIAGRAMS_CONVERTED=0

# Process each markdown file in content/posts/
while IFS= read -r -d '' file; do
    # Get absolute path for Docker volume mounting
    FULLPATH=$(realpath "$file")
    DIR=$(dirname "$FULLPATH")
    BASENAME=$(basename "$file" .md)
    FILENAME=$(basename "$file")

    # Check if file contains mermaid blocks
    if grep -q '```mermaid' "$file"; then
        echo "  ▶️  Converting diagrams in: $(basename $DIR)/$FILENAME"

        # Run Mermaid CLI in Docker with absolute paths and proper user permissions
        docker run --rm \
            --user "$(id -u):$(id -g)" \
            -v "$DIR":/data \
            -v "$SCRIPT_DIR/.mermaidrc":/data/.mermaidrc \
            minlag/mermaid-cli:10.8.0 \
            -i "$FILENAME" \
            -o "$BASENAME.svg" \
            --configFile .mermaidrc \
            --backgroundColor transparent \
            2>&1 | grep -E "(Generated|Generating|Error)" || true

        DIAGRAMS_CONVERTED=$((DIAGRAMS_CONVERTED + 1))
    fi
done < <(find "$SCRIPT_DIR/content/posts" -name "*.md" -print0)

if [ $DIAGRAMS_CONVERTED -eq 0 ]; then
    echo "  ℹ️  No Mermaid diagrams found"
else
    echo "  ✅ Converted diagrams in $DIAGRAMS_CONVERTED files"
fi

echo ""

# Step 4: Build Hugo site
echo "🏗️  Step 4: Building Hugo site..."
cd "$SCRIPT_DIR"

# Check if hugo is available
if ! command -v hugo &> /dev/null; then
    if [ -f "$HOME/bin/hugo" ]; then
        HUGO="$HOME/bin/hugo"
    else
        echo "❌ Hugo not found in PATH or ~/bin/hugo"
        exit 1
    fi
else
    HUGO="hugo"
fi

echo "  Using Hugo: $HUGO"
$HUGO --cleanDestinationDir

echo ""
echo "✅ Build complete!"
echo ""
echo "Next steps:"
echo "  - Test locally: cd $SCRIPT_DIR && $HUGO server"
echo "  - Deploy: git add . && git commit && git push"
