#!/usr/bin/env sh

set -eu

CF_VERSION="${CF_VERSION:-$(git ls-remote --tags --refs https://github.com/cloudflare/cloudflared.git \
	| awk -F/ '{print $NF}' | grep -E '^[0-9]{4}\.[0-9]+\.[0-9]+$' | sort -V | tail -1)}"
mkdir -p "$(dirname "${OUT:-./out/cloudflared}")"
OUT_DIR="$(cd "$(dirname "${OUT:-./out/cloudflared}")" && pwd)"
OUT_NAME="$(basename "${OUT:-./out/cloudflared}")"

echo "Building cloudflared ${CF_VERSION} -> ${OUT_DIR}/${OUT_NAME}"

docker run --rm -e MSYS_NO_PATHCONV=1 \
	-v "${OUT_DIR}:/out" \
	-e HOME=/tmp -e GOCACHE=/tmp/gocache -e GOMODCACHE=/tmp/gomodcache \
	golang:1.24-bookworm sh -c "
		set -eu
		git clone --branch '$CF_VERSION' --depth 1 https://github.com/cloudflare/cloudflared.git /src
		cd /src
		VERSION=\$(git describe --tags --always --match '[0-9][0-9][0-9][0-9].*.*')
		CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=5 GOTOOLCHAIN=auto \
			go build -mod=mod -ldflags=\"-s -w -X main.Version=\$VERSION -X github.com/cloudflare/cloudflared/metrics.Runtime=virtual\" \
			-o /out/${OUT_NAME} ./cmd/cloudflared
		chmod +x /out/${OUT_NAME}
	"

echo "--- stripped size ---"
ls -la "${OUT_DIR}/${OUT_NAME}"

docker run --rm -v "${OUT_DIR}:/out" alpine:3.22 sh -c "
	apk add --no-cache upx file >/dev/null
	file /out/${OUT_NAME}
	upx --best --lzma /out/${OUT_NAME}
"

echo "--- final (upx-compressed) size ---"
ls -la "${OUT_DIR}/${OUT_NAME}"
