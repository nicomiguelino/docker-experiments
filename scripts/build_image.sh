#!/usr/bin/env bash

set -euo pipefail

# Default values
PLATFORM=""
BUILD_COMMAND=""

# Function to print usage
usage() {
    echo "Usage: $0 --platform <pi1|pi2|pi3|pi4|pi5> [--build-command <command>]"
    echo
    echo "Options:"
    echo "  --platform       Specify the target Raspberry Pi platform"
    echo "  --build-command  Optional build command to execute during image build"
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --build-command)
            BUILD_COMMAND="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate platform
if [[ -z "$PLATFORM" ]]; then
    echo "Error: --platform is required"
    usage
fi

# Map platform to base image and architecture
case "$PLATFORM" in
    "pi1")
        export BASE_IMAGE="balenalib/raspberry-pi-debian"
        ARCH="linux/arm/v6"
        ;;
    "pi2")
        export BASE_IMAGE="balenalib/raspberry-pi2-debian"
        ARCH="linux/arm/v7"
        ;;
    "pi3")
        export BASE_IMAGE="balenalib/raspberrypi3-debian"
        ARCH="linux/arm/v7"
        ;;
    "pi4")
        export BASE_IMAGE="balenalib/raspberrypi4-64-debian"
        ARCH="linux/arm64"
        ;;
    "pi5")
        export BASE_IMAGE="balenalib/raspberrypi5-debian"
        ARCH="linux/arm64"
        ;;
    *)
        echo "Error: Invalid platform. Must be one of: pi1, pi2, pi3, pi4, pi5"
        exit 1
        ;;
esac

# Set environment variables
export BASE_TAG="bookworm"
export BUILD_COMMAND="${BUILD_COMMAND:-echo 'No build command specified'}"

# Create docker build directory if it doesn't exist
DOCKER_BUILD_DIR="docker/build"
mkdir -p "$DOCKER_BUILD_DIR"

# Generate Dockerfile from template
echo "Generating Dockerfile for platform: $PLATFORM"
envsubst < docker/Dockerfile.template > "$DOCKER_BUILD_DIR/Dockerfile"

# Build the image using buildx
echo "Building for platform: $PLATFORM ($ARCH)"
echo "Using base image: $BASE_IMAGE:$BASE_TAG"

# Ensure cache directory exists
mkdir -p /tmp/.buildx-cache

docker buildx build \
    --platform "$ARCH" \
    --file "$DOCKER_BUILD_DIR/Dockerfile" \
    --tag "raspberry-$PLATFORM:latest" \
    --cache-from "type=local,src=/tmp/.buildx-cache" \
    --cache-to "type=local,dest=/tmp/.buildx-cache,mode=max" \
    --progress=plain \
    --load \
    .

# Clean up
rm -f "$DOCKER_BUILD_DIR/Dockerfile"

echo "Build completed successfully!"
