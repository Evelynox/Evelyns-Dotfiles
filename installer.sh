#!/bin/bash

set -e

# Standard-Dotfiles-Verzeichnis
DEFAULT_DOTFILES_DIR="$HOME/Addivs-Dotfiles"

# Benutzer nach Pfad fragen, wenn Standardverzeichnis fehlt
if [ ! -d "$DEFAULT_DOTFILES_DIR" ]; then
    echo "Default dotfiles directory ($DEFAULT_DOTFILES_DIR) not found."
    read -rp "Please enter the path to your dotfiles directory: " CUSTOM_PATH

    if [ ! -d "$CUSTOM_PATH" ]; then
        echo "Error: Directory does not exist."
        exit 1
    fi

    DOTFILES_DIR="$CUSTOM_PATH"
else
    DOTFILES_DIR="$DEFAULT_DOTFILES_DIR"
fi

TARGET_DIR="$HOME"

echo ""
echo "Available dotfile sets in: $DOTFILES_DIR"
select set in $(ls "$DOTFILES_DIR"); do
    if [ -n "$set" ]; then
        SELECTED_SET="$set"
        break
    else
        echo "Invalid selection."
    fi
done

SOURCE_PATH="$DOTFILES_DIR/$SELECTED_SET"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y-%m-%d_%H-%M-%S)"

echo ""
echo "🔄 Backing up existing files to: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Kopiert Dateien oder erstellt Ordner, inkl. Backup vorhandener Elemente
copy_with_backup() {
    local src="$1"
    local rel_path="${src#$SOURCE_PATH/}"
    local dest="$TARGET_DIR/$rel_path"

    if [ -d "$src" ]; then
        mkdir -p "$dest"
    else
        mkdir -p "$(dirname "$dest")"
        if [ -e "$dest" ] || [ -L "$dest" ]; then
            mkdir -p "$BACKUP_DIR/$(dirname "$rel_path")"
            mv "$dest" "$BACKUP_DIR/$rel_path"
        fi
        cp -r "$src" "$dest"
    fi
}

echo "📦 Installing dotfiles from: $SOURCE_PATH"
find "$SOURCE_PATH" | while read -r item; do
    copy_with_backup "$item"
done

# Optional: Pakete installieren
PKG_LIST="$SOURCE_PATH/packages.txt"
if [ -f "$PKG_LIST" ]; then
    echo ""
    echo "📚 Installing packages listed in packages.txt ..."
    yay -S --noconfirm --needed $(cat "$PKG_LIST")
fi

echo ""
echo "✅ Dotfiles from '$SELECTED_SET' installed successfully."
