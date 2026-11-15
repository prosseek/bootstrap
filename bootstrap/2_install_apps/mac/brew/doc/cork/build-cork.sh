#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================="
echo "Cork Auto Compiler"
echo "==========================================${NC}"
echo ""

# Check if Xcode Command Line Tools are installed
if ! xcode-select -p &> /dev/null; then
    echo -e "${RED}Error: Xcode Command Line Tools not installed${NC}"
    echo "Please install with: xcode-select --install"
    exit 1
fi

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git not found${NC}"
    exit 1
fi

# Set directories
BUILD_DIR="${HOME}/temp/cork-build"
REPO_URL="https://github.com/buresdv/Cork.git"

echo -e "${YELLOW}Step 1: Preparing build directory...${NC}"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Clone or update repository
if [ -d "Cork" ]; then
    echo -e "${YELLOW}Repository exists. Pulling latest changes...${NC}"
    cd Cork
    git pull
else
    echo -e "${YELLOW}Cloning Cork repository...${NC}"
    git clone "$REPO_URL"
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Failed to clone repository${NC}"
        exit 1
    fi
    cd Cork
fi

echo -e "${GREEN}✓ Repository ready${NC}"
echo ""

# Check if Tuist is installed
echo -e "${YELLOW}Step 2: Checking for Tuist...${NC}"
if ! command -v tuist &> /dev/null; then
    echo "Tuist not found. Installing via Homebrew..."
    brew install --cask tuist
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Failed to install Tuist${NC}"
        echo "Please install manually: brew install --cask tuist"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Tuist is ready${NC}"
echo ""

# Install Tuist dependencies
echo -e "${YELLOW}Step 3: Installing Tuist dependencies...${NC}"
tuist install

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to install dependencies${NC}"
    echo "Check the error message above for details"
    exit 1
fi

echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Generate Xcode project using Tuist
echo -e "${YELLOW}Step 4: Generating Xcode project with Tuist...${NC}"
tuist generate

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to generate Xcode project${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Xcode project generated${NC}"
echo ""

# Find the generated project/workspace
if [ -d "Cork.xcworkspace" ]; then
    PROJECT_FILE="Cork.xcworkspace"
    PROJECT_FLAG="-workspace"
elif [ -d "Cork.xcodeproj" ]; then
    PROJECT_FILE="Cork.xcodeproj"
    PROJECT_FLAG="-project"
else
    echo -e "${RED}✗ No Xcode project or workspace found after generation${NC}"
    ls -la
    exit 1
fi

echo "Using: $PROJECT_FILE"
echo ""

# Build the app
echo -e "${YELLOW}Step 5: Building Cork...${NC}"
echo "This may take a few minutes..."
echo -e "${YELLOW}Note: Skipping package plugin validation to avoid SwiftLint issues${NC}"
echo ""

xcodebuild \
    $PROJECT_FLAG "$PROJECT_FILE" \
    -scheme Cork \
    -configuration Release \
    -derivedDataPath "${BUILD_DIR}/DerivedData" \
    -skipPackagePluginValidation \
    -skipMacroValidation \
    clean build

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Build successful!${NC}"
    echo ""
    
    # Find the built app
    BUILT_APP=$(find "${BUILD_DIR}/DerivedData" -name "Cork.app" -type d | head -n 1)
    
    if [ -n "$BUILT_APP" ]; then
        echo -e "${YELLOW}Step 6: Installing Cork...${NC}"
        
        # Remove old version if exists
        if [ -d "/Applications/Cork.app" ]; then
            echo "Removing old version..."
            rm -rf "/Applications/Cork.app"
        fi
        
        # Copy to Applications
        echo "Copying to Applications folder..."
        cp -R "$BUILT_APP" /Applications/
        
        echo -e "${GREEN}✓ Cork installed successfully!${NC}"
        echo ""
        echo -e "${BLUE}=========================================="
        echo "Installation Complete!"
        echo "==========================================${NC}"
        echo ""
        echo "Cork has been installed to /Applications/Cork.app"
        echo ""
        echo -e "${YELLOW}Note: You may need to allow the app in System Settings > Privacy & Security${NC}"
        echo ""
        
        # Ask if user wants to open Cork
        read -p "Do you want to open Cork now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            open /Applications/Cork.app
        fi
        
        # Ask if user wants to cleanup
        echo ""
        read -p "Do you want to cleanup build files? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd ~
            rm -rf "$BUILD_DIR"
            echo -e "${GREEN}✓ Cleanup complete${NC}"
        else
            echo "Build files kept at: $BUILD_DIR"
        fi
    else
        echo -e "${RED}✗ Built app not found${NC}"
        echo "Searching in:"
        find "${BUILD_DIR}/DerivedData" -name "*.app" -type d
        exit 1
    fi
else
    echo -e "${RED}✗ Build failed${NC}"
    echo ""
    echo "Common issues:"
    echo "1. Xcode not installed: Install from App Store"
    echo "2. License agreement: Run 'sudo xcodebuild -license accept'"
    echo "3. Check build logs above for specific errors"
    exit 1
fi

echo ""
echo -e "${BLUE}=========================================="
echo "Done!"
echo "==========================================${NC}"
