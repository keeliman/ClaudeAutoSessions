#!/bin/bash

# ClaudeScheduler Professional DMG Creation Script
# Creates a professional distribution package with custom background, icons, and layout
# Usage: ./create_distribution_dmg.sh [version]

set -e

# Configuration
APP_NAME="ClaudeScheduler"
BUNDLE_ID="com.anthropic.claudescheduler"
VERSION=${1:-"1.0.0"}
BUILD_DIR="./build"
DMG_DIR="./dmg_temp"
FINAL_DMG_NAME="${APP_NAME}_${VERSION}.dmg"
VOLUME_NAME="${APP_NAME} ${VERSION}"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
APP_PATH="${PROJECT_ROOT}/build/Release/${APP_NAME}.app"
ASSETS_DIR="${PROJECT_ROOT}/DMG_Assets"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "Required command '$1' not found. Please install it first."
        exit 1
    fi
}

# Function to create DMG assets
create_dmg_assets() {
    log_info "Creating DMG assets..."
    
    # Create assets directory
    mkdir -p "$ASSETS_DIR"
    
    # Create custom background (placeholder - in production you'd have a designed background)
    cat > "$ASSETS_DIR/create_background.py" << 'EOF'
#!/usr/bin/env python3
import os
from PIL import Image, ImageDraw, ImageFont
import sys

def create_dmg_background():
    # Create a high-quality background image
    width, height = 660, 420
    img = Image.new('RGB', (width, height), color='#f5f5f5')
    draw = ImageDraw.Draw(img)
    
    # Add gradient background
    for y in range(height):
        color_value = int(245 - (y / height) * 20)
        color = (color_value, color_value, color_value)
        draw.line([(0, y), (width, y)], fill=color)
    
    # Add title
    try:
        # Try to use a system font
        font = ImageFont.truetype('/System/Library/Fonts/SF-Pro-Display-Medium.otf', 24)
    except:
        try:
            font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 24)
        except:
            font = ImageFont.load_default()
    
    title = "ClaudeScheduler"
    subtitle = "Enterprise-Grade Productivity Scheduler"
    
    # Calculate text position
    title_bbox = draw.textbbox((0, 0), title, font=font)
    title_width = title_bbox[2] - title_bbox[0]
    title_x = (width - title_width) // 2
    
    # Draw title
    draw.text((title_x, 50), title, fill='#1e293b', font=font)
    
    # Draw subtitle
    try:
        subtitle_font = ImageFont.truetype('/System/Library/Fonts/SF-Pro-Display-Regular.otf', 14)
    except:
        subtitle_font = font
    
    subtitle_bbox = draw.textbbox((0, 0), subtitle, font=subtitle_font)
    subtitle_width = subtitle_bbox[2] - subtitle_bbox[0]
    subtitle_x = (width - subtitle_width) // 2
    draw.text((subtitle_x, 85), subtitle, fill='#64748b', font=subtitle_font)
    
    # Add installation instructions
    instructions = [
        "1. Drag ClaudeScheduler to Applications folder",
        "2. Launch from Applications or Spotlight",
        "3. Grant necessary permissions when prompted"
    ]
    
    try:
        inst_font = ImageFont.truetype('/System/Library/Fonts/SF-Pro-Display-Regular.otf', 12)
    except:
        inst_font = font
    
    for i, instruction in enumerate(instructions):
        draw.text((50, 320 + i * 20), instruction, fill='#475569', font=inst_font)
    
    # Add decorative elements
    # App icon placeholder (in production, you'd composite the actual icon)
    icon_size = 64
    icon_x, icon_y = 150, 150
    draw.ellipse([icon_x, icon_y, icon_x + icon_size, icon_y + icon_size], 
                fill='#3b82f6', outline='#1e40af', width=2)
    
    # Arrow pointing to Applications
    arrow_start_x = icon_x + icon_size + 40
    arrow_end_x = width - 150
    arrow_y = icon_y + icon_size // 2
    
    draw.line([(arrow_start_x, arrow_y), (arrow_end_x - 20, arrow_y)], 
             fill='#64748b', width=3)
    draw.polygon([(arrow_end_x - 20, arrow_y - 8), 
                  (arrow_end_x, arrow_y), 
                  (arrow_end_x - 20, arrow_y + 8)], 
                fill='#64748b')
    
    # Applications folder icon placeholder
    folder_size = 64
    folder_x = width - 150
    folder_y = icon_y
    draw.rectangle([folder_x, folder_y, folder_x + folder_size, folder_y + folder_size], 
                  fill='#fbbf24', outline='#f59e0b', width=2)
    draw.text((folder_x + 8, folder_y + 25), "Apps", fill='#78350f', font=inst_font)
    
    # Save the image
    output_path = os.path.join(os.path.dirname(__file__), 'dmg_background.png')
    img.save(output_path, 'PNG', quality=95)
    print(f"Background created: {output_path}")

if __name__ == "__main__":
    create_dmg_background()
EOF
    
    # Create background image if Python and PIL are available
    if command -v python3 &> /dev/null && python3 -c "import PIL" 2>/dev/null; then
        python3 "$ASSETS_DIR/create_background.py"
    else
        log_warning "Python3 with PIL not available. Using default background."
        # Create a simple background with native tools
        sips -z 420 660 -c 660 420 -p /System/Library/Desktop\ Pictures/Solid\ Colors/Space\ Gray.png "$ASSETS_DIR/dmg_background.png" 2>/dev/null || true
    fi
    
    # Create volume icon (using app icon if available)
    if [ -f "$APP_PATH/Contents/Resources/AppIcon.icns" ]; then
        cp "$APP_PATH/Contents/Resources/AppIcon.icns" "$ASSETS_DIR/VolumeIcon.icns"
    else
        log_warning "App icon not found. DMG will use default volume icon."
    fi
    
    # Create DS_Store template for window layout
    cat > "$ASSETS_DIR/ds_store_template.py" << 'EOF'
#!/usr/bin/env python3
import os
import struct

def create_ds_store():
    """Create a .DS_Store file with optimal window layout"""
    # This is a simplified version - in production you'd use a proper .DS_Store generator
    # or copy from a manually configured template
    
    print("DS_Store template created (placeholder)")

if __name__ == "__main__":
    create_ds_store()
EOF
    
    log_success "DMG assets created successfully"
}

# Function to build the application
build_application() {
    log_info "Building ${APP_NAME} for release..."
    
    cd "$PROJECT_ROOT"
    
    # Clean previous builds
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
    fi
    
    # Build the application
    xcodebuild -project "${APP_NAME}.xcodeproj" \
               -scheme "$APP_NAME" \
               -configuration Release \
               -derivedDataPath "$BUILD_DIR" \
               -archivePath "${BUILD_DIR}/${APP_NAME}.xcarchive" \
               archive
    
    if [ $? -ne 0 ]; then
        log_error "Failed to build application"
        exit 1
    fi
    
    # Export the application
    xcodebuild -exportArchive \
               -archivePath "${BUILD_DIR}/${APP_NAME}.xcarchive" \
               -exportPath "${BUILD_DIR}/Release" \
               -exportOptionsPlist "${SCRIPT_DIR}/ExportOptions.plist"
    
    if [ $? -ne 0 ]; then
        log_error "Failed to export application"
        exit 1
    fi
    
    log_success "Application built successfully"
}

# Function to create export options plist
create_export_options() {
    log_info "Creating export options..."
    
    cat > "${SCRIPT_DIR}/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
EOF
    
    log_success "Export options created"
}

# Function to sign the application
sign_application() {
    log_info "Signing application..."
    
    # Check if we have signing identity
    SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | cut -d '"' -f 2)
    
    if [ -z "$SIGNING_IDENTITY" ]; then
        log_warning "No Developer ID Application certificate found. Skipping code signing."
        return 0
    fi
    
    log_info "Using signing identity: $SIGNING_IDENTITY"
    
    # Sign the application
    codesign --force \
             --verify \
             --verbose \
             --sign "$SIGNING_IDENTITY" \
             --options runtime \
             --timestamp \
             "$APP_PATH"
    
    if [ $? -eq 0 ]; then
        log_success "Application signed successfully"
        
        # Verify signature
        codesign --verify --verbose=2 "$APP_PATH"
        spctl --assess --verbose=2 "$APP_PATH"
    else
        log_error "Failed to sign application"
        exit 1
    fi
}

# Function to notarize the application
notarize_application() {
    log_info "Preparing for notarization..."
    
    # Check for notarization credentials
    if ! security find-generic-password -a "AC_USERNAME" &>/dev/null; then
        log_warning "Notarization credentials not found. Skipping notarization."
        log_info "To enable notarization, store your credentials using:"
        log_info "xcrun notarytool store-credentials \"notarytool-profile\" --apple-id \"your-email@example.com\" --team-id \"YOUR_TEAM_ID\""
        return 0
    fi
    
    # Create a zip file for notarization
    NOTARIZATION_ZIP="${BUILD_DIR}/${APP_NAME}_notarization.zip"
    
    log_info "Creating notarization package..."
    ditto -c -k --keepParent "$APP_PATH" "$NOTARIZATION_ZIP"
    
    # Submit for notarization
    log_info "Submitting for notarization (this may take several minutes)..."
    xcrun notarytool submit "$NOTARIZATION_ZIP" \
                           --keychain-profile "notarytool-profile" \
                           --wait
    
    if [ $? -eq 0 ]; then
        log_success "Application notarized successfully"
        
        # Staple the notarization
        log_info "Stapling notarization..."
        xcrun stapler staple "$APP_PATH"
        
        # Verify stapling
        xcrun stapler validate "$APP_PATH"
    else
        log_error "Notarization failed"
        exit 1
    fi
}

# Function to create the DMG
create_dmg() {
    log_info "Creating DMG package..."
    
    # Clean previous DMG temp directory
    if [ -d "$DMG_DIR" ]; then
        rm -rf "$DMG_DIR"
    fi
    mkdir -p "$DMG_DIR"
    
    # Copy application to DMG directory
    cp -R "$APP_PATH" "$DMG_DIR/"
    
    # Create Applications alias
    ln -s /Applications "$DMG_DIR/Applications"
    
    # Copy additional files
    if [ -f "${PROJECT_ROOT}/README.md" ]; then
        cp "${PROJECT_ROOT}/README.md" "$DMG_DIR/README.txt"
    fi
    
    if [ -f "${PROJECT_ROOT}/LICENSE" ]; then
        cp "${PROJECT_ROOT}/LICENSE" "$DMG_DIR/License.txt"
    fi
    
    # Create uninstaller script
    cat > "$DMG_DIR/Uninstall ClaudeScheduler.command" << 'EOF'
#!/bin/bash
echo "ClaudeScheduler Uninstaller"
echo "=========================="
echo

# Remove application
if [ -d "/Applications/ClaudeScheduler.app" ]; then
    echo "Removing ClaudeScheduler.app..."
    rm -rf "/Applications/ClaudeScheduler.app"
fi

# Remove launch agent
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.anthropic.claudescheduler.plist"
if [ -f "$LAUNCH_AGENT" ]; then
    echo "Removing launch agent..."
    launchctl unload "$LAUNCH_AGENT" 2>/dev/null
    rm "$LAUNCH_AGENT"
fi

# Remove application support files
APP_SUPPORT="$HOME/Library/Application Support/ClaudeScheduler"
if [ -d "$APP_SUPPORT" ]; then
    echo "Removing application support files..."
    rm -rf "$APP_SUPPORT"
fi

# Remove preferences
PREFS="$HOME/Library/Preferences/com.anthropic.claudescheduler.plist"
if [ -f "$PREFS" ]; then
    echo "Removing preferences..."
    rm "$PREFS"
fi

echo
echo "ClaudeScheduler has been successfully uninstalled."
echo "You can safely delete this installer."
echo
read -p "Press Enter to continue..."
EOF
    
    chmod +x "$DMG_DIR/Uninstall ClaudeScheduler.command"
    
    # Copy custom background if available
    if [ -f "$ASSETS_DIR/dmg_background.png" ]; then
        cp "$ASSETS_DIR/dmg_background.png" "$DMG_DIR/.background.png"
        # Hide the background file
        SetFile -a V "$DMG_DIR/.background.png" 2>/dev/null || true
    fi
    
    # Calculate DMG size (add 50MB for overhead)
    DMG_SIZE_MB=$(du -sm "$DMG_DIR" | cut -f1)
    DMG_SIZE_MB=$((DMG_SIZE_MB + 50))
    
    # Create temporary DMG
    TEMP_DMG="${BUILD_DIR}/temp_${FINAL_DMG_NAME}"
    hdiutil create -srcfolder "$DMG_DIR" \
                   -volname "$VOLUME_NAME" \
                   -fs HFS+ \
                   -fsargs "-c c=64,a=16,e=16" \
                   -format UDZO \
                   -imagekey zlib-level=9 \
                   -size "${DMG_SIZE_MB}m" \
                   "$TEMP_DMG"
    
    # Mount DMG for customization
    log_info "Mounting DMG for customization..."
    MOUNT_DIR="/Volumes/$VOLUME_NAME"
    
    # Unmount if already mounted
    if [ -d "$MOUNT_DIR" ]; then
        hdiutil detach "$MOUNT_DIR" 2>/dev/null || true
    fi
    
    hdiutil attach "$TEMP_DMG" -mountpoint "$MOUNT_DIR"
    
    # Set volume icon if available
    if [ -f "$ASSETS_DIR/VolumeIcon.icns" ]; then
        cp "$ASSETS_DIR/VolumeIcon.icns" "$MOUNT_DIR/.VolumeIcon.icns"
        SetFile -a C "$MOUNT_DIR" 2>/dev/null || true
    fi
    
    # Apply window settings using AppleScript
    log_info "Configuring DMG window layout..."
    osascript << EOF
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 760, 520}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 72
        set background picture of theViewOptions to file ".background.png"
        
        -- Position items
        set position of item "ClaudeScheduler.app" of container window to {150, 180}
        set position of item "Applications" of container window to {500, 180}
        if exists item "README.txt" then
            set position of item "README.txt" of container window to {150, 300}
        end if
        if exists item "Uninstall ClaudeScheduler.command" then
            set position of item "Uninstall ClaudeScheduler.command" of container window to {500, 300}
        end if
        
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF
    
    # Unmount DMG
    hdiutil detach "$MOUNT_DIR"
    
    # Convert to final DMG
    log_info "Creating final DMG..."
    hdiutil convert "$TEMP_DMG" \
                    -format UDZO \
                    -imagekey zlib-level=9 \
                    -o "${BUILD_DIR}/${FINAL_DMG_NAME}"
    
    # Clean up
    rm "$TEMP_DMG"
    rm -rf "$DMG_DIR"
    
    # Verify DMG
    hdiutil verify "${BUILD_DIR}/${FINAL_DMG_NAME}"
    
    log_success "DMG created successfully: ${BUILD_DIR}/${FINAL_DMG_NAME}"
}

# Function to create checksum and signature
create_checksums() {
    log_info "Creating checksums and signature files..."
    
    cd "$BUILD_DIR"
    
    # Create SHA256 checksum
    shasum -a 256 "$FINAL_DMG_NAME" > "${FINAL_DMG_NAME}.sha256"
    
    # Create MD5 checksum (for legacy compatibility)
    md5 -r "$FINAL_DMG_NAME" | sed 's/ / */' > "${FINAL_DMG_NAME}.md5"
    
    # Create file info
    cat > "${FINAL_DMG_NAME}.info" << EOF
ClaudeScheduler Distribution Package
====================================

File: $FINAL_DMG_NAME
Version: $VERSION
Build Date: $(date)
Size: $(du -h "$FINAL_DMG_NAME" | cut -f1)

System Requirements:
- macOS 13.0 or later
- Apple Silicon or Intel processor
- 100 MB available space

Installation:
1. Double-click the DMG file to mount it
2. Drag ClaudeScheduler.app to Applications folder
3. Launch from Applications or Spotlight
4. Grant permissions when prompted

Support:
- GitHub: https://github.com/anthropic-ai/claude-cli
- Issues: https://github.com/anthropic-ai/claude-cli/issues

EOF
    
    log_success "Distribution files created successfully"
}

# Function to display final information
display_final_info() {
    echo
    log_success "🎉 ClaudeScheduler Distribution Package Created Successfully!"
    echo
    echo "📦 Package Information:"
    echo "   • DMG File: ${BUILD_DIR}/${FINAL_DMG_NAME}"
    echo "   • Version: $VERSION"
    echo "   • Size: $(du -h "${BUILD_DIR}/${FINAL_DMG_NAME}" | cut -f1)"
    echo "   • Checksum: ${BUILD_DIR}/${FINAL_DMG_NAME}.sha256"
    echo
    echo "🚀 Next Steps:"
    echo "   1. Test the DMG on a clean system"
    echo "   2. Upload to your distribution platform"
    echo "   3. Update release notes and documentation"
    echo "   4. Notify users of the new release"
    echo
    echo "📋 Distribution Checklist:"
    echo "   ✓ Application built and optimized"
    echo "   ✓ Code signed (if certificate available)"
    echo "   ✓ Notarized (if credentials configured)"
    echo "   ✓ Professional DMG package created"
    echo "   ✓ Checksums and documentation included"
    echo "   ✓ Uninstaller provided"
    echo
}

# Main execution
main() {
    log_info "Starting ClaudeScheduler DMG creation process..."
    
    # Check prerequisites
    check_command "xcodebuild"
    check_command "hdiutil"
    check_command "codesign"
    
    # Create directory structure
    mkdir -p "$BUILD_DIR"
    
    # Execute build pipeline
    create_export_options
    create_dmg_assets
    build_application
    sign_application
    notarize_application
    create_dmg
    create_checksums
    
    # Display final information
    display_final_info
    
    log_success "ClaudeScheduler distribution package ready for deployment! 🚀"
}

# Run main function
main "$@"