#!/usr/bin/env bash
# Build the exact artifacts consumed by server/internal/updater.
set -euo pipefail

dest=${1:?usage: build-release.sh OUTPUT_DIRECTORY}
mkdir -p -- "$dest"
dest="$(cd -- "$dest" && pwd)"
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.."
version="$(cat VERSION)"
[[ "$version" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]
cd server
[[ -f web/index.html ]] || { echo 'Build the frontend before embedding it.' >&2; exit 1; }

build() {
  local os="$1" arch="$2" suffix="${3-}"
  CGO_ENABLED=0 GOOS="$os" GOARCH="$arch" go build -tags ui -trimpath \
    -ldflags "-s -w -X github.com/ovh-buy/server/internal/handlers.Version=$version" \
    -o "$dest/ovh-server-$os-$arch$suffix" .
}

build linux amd64
build linux arm64
build windows amd64 .exe

cd -- "$dest"
sha256sum ovh-server-linux-amd64 ovh-server-linux-arm64 ovh-server-windows-amd64.exe > checksums.txt
sha256sum --strict --check checksums.txt
