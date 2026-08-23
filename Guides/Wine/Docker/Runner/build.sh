#!/usr/bin/env bash
# Build the GameDirection Wine runner and extract the packaged tarball.
#
# Run from anywhere; this script cds to the right build context itself.
# See Runner/README.md for what this produces and how to verify it.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WINE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"   # Guides/Wine
BASE_IMAGE="${1:-debian:10}"
WINE_VERSION="${WINE_VERSION:-11.15}"
IMAGE_TAG="gamedirection-wine-runner:${WINE_VERSION}"
TARBALL="GameDirectionWine-Runner-x86_64.tar.xz"

echo "Building ${IMAGE_TAG} from base ${BASE_IMAGE} (Wine ${WINE_VERSION})..."
docker build \
    --build-arg BASE_IMAGE="${BASE_IMAGE}" \
    --build-arg WINE_VERSION="${WINE_VERSION}" \
    -f "${SCRIPT_DIR}/Dockerfile" \
    -t "${IMAGE_TAG}" \
    "${WINE_DIR}"

echo "Extracting packaged output..."
CONTAINER_ID="$(docker create "${IMAGE_TAG}")"
trap 'docker rm -f "${CONTAINER_ID}" >/dev/null' EXIT

rm -rf ./out
mkdir -p ./out
docker cp "${CONTAINER_ID}:/gamedirection-wine" ./out/gamedirection-wine

tar -C ./out -cJf "${TARBALL}" gamedirection-wine
echo "Done: ${TARBALL}"
echo
echo "Cross-container portability check (run this manually against a DIFFERENT"
echo "distro than ${BASE_IMAGE}, e.g. fedora:41 or archlinux:latest):"
echo "  docker run --rm -v \"\$PWD/out/gamedirection-wine:/opt/gamedirection-wine\" \\"
echo "    -e WINEPREFIX=/tmp/wineprefix <other-distro-image> \\"
echo "    /opt/gamedirection-wine/bin/wine --version"
