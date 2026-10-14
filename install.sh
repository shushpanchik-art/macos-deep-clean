#!/bin/bash
# macOS Deep Clean - One-line installer

INSTALL_DIR="$HOME"
SCRIPT_NAME="macos-deep-clean.sh"
SCRIPT_URL="https://raw.githubusercontent.com/shushpanchik-art/macos-deep-clean/main/macos-deep-clean.sh"

echo "════════════════════════════════════════════════════"
echo "   macOS Deep Clean - Installer"
echo "════════════════════════════════════════════════════"
echo ""

# Download script
echo "📥 Downloading script..."
curl -fsSL "$SCRIPT_URL" -o "$INSTALL_DIR/$SCRIPT_NAME"

if [ $? -ne 0 ]; then
    echo "❌ Download failed!"
    exit 1
fi

# Make executable
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
echo "✅ Script downloaded to $INSTALL_DIR/$SCRIPT_NAME"
echo ""

# Add alias to shell config
SHELL_CONFIG=""
if [ -f "$HOME/.zshrc" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
fi

if [ -n "$SHELL_CONFIG" ]; then
    # Check if alias already exists
    if ! grep -q "alias clean=" "$SHELL_CONFIG"; then
        echo "" >> "$SHELL_CONFIG"
        echo "# macOS Deep Clean alias" >> "$SHELL_CONFIG"
        echo "alias clean='$INSTALL_DIR/$SCRIPT_NAME'" >> "$SHELL_CONFIG"
        echo "✅ Alias 'clean' added to $SHELL_CONFIG"
        echo ""
        echo "Run this to activate:"
        echo "  source $SHELL_CONFIG"
    else
        echo "✅ Alias 'clean' already exists"
    fi
else
    echo "⚠️  Could not find .zshrc or .bashrc"
    echo "   Add this manually:"
    echo "   alias clean='$INSTALL_DIR/$SCRIPT_NAME'"
fi

echo ""
echo "════════════════════════════════════════════════════"
echo "✅ Installation complete!"
echo "════════════════════════════════════════════════════"
echo ""
echo "Usage:"
echo "  clean              # Full deep clean"
echo "  clean --quick      # Quick clean"
echo "  clean --orphans    # Remove orphans only"
echo "  clean --help       # Show help"
echo ""
