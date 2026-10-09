#!/bin/sh
set -eu

cd -- "$(dirname -- "$0")"

: "${WORKER_BUILD_BIN:?Set WORKER_BUILD_BIN to the verified worker-build executable}"
: "${ESBUILD_BIN:?Set ESBUILD_BIN to the verified esbuild executable}"
: "${WASM_BINDGEN_BIN:?Set WASM_BINDGEN_BIN to the verified wasm-bindgen executable}"

for tool in "$WORKER_BUILD_BIN" "$ESBUILD_BIN" "$WASM_BINDGEN_BIN"; do
    case "$tool" in
        /*) ;;
        *) echo "Build tool paths must be absolute: $tool" >&2; exit 1 ;;
    esac
    if [ ! -f "$tool" ] || [ ! -x "$tool" ]; then
        echo "Build tool is missing or not executable: $tool" >&2
        exit 1
    fi
done

exec sandbox-exec -f build.sb env CARGO_NET_OFFLINE=true \
    "$WORKER_BUILD_BIN" --release --no-opt -- --offline --locked
