#!/usr/bin/env bash
set -euo pipefail

case "${RUNNER_OS:-$(uname -s)}" in
  Linux)
    FLAGS="-lopenblas -llapack -lm"
    STUB_CFLAGS=""
    ;;
  macOS | Darwin)
    FLAGS="-framework Accelerate"
    STUB_CFLAGS=""
    ;;
  Windows | MINGW* | MSYS* | CYGWIN*)
    FLAGS="-LC:/msys64/mingw64/lib -lopenblas"
    STUB_CFLAGS="-IC:/msys64/mingw64/include -IC:/msys64/mingw64/include/openblas"
    ;;
  *)
    echo "unsupported runner OS: ${RUNNER_OS:-$(uname -s)}" >&2
    exit 1
    ;;
esac

for pkg in \
  src/nash/moon.pkg \
  src/payoff/moon.pkg \
  .mooncakes/mizchi/numbt/src/moon.pkg \
  .mooncakes/mizchi/blas/src/moon.pkg \
  .mooncakes/mizchi/blas/src/bench/moon.pkg
do
  if [ -f "$pkg" ]; then
    sed -i.bak "s|\"cc-link-flags\": \"[^\"]*\"|\"cc-link-flags\": \"$FLAGS\"|g" "$pkg"
    if [ -n "$STUB_CFLAGS" ]; then
      if grep -q '"stub-cc-flags":' "$pkg"; then
        sed -i.bak "s|\"stub-cc-flags\": \"[^\"]*\"|\"stub-cc-flags\": \"$STUB_CFLAGS\"|g" "$pkg"
      else
        sed -i.bak "s|\"cc-link-flags\": \"$FLAGS\"|\"cc-link-flags\": \"$FLAGS\", \"stub-cc-flags\": \"$STUB_CFLAGS\"|g" "$pkg"
      fi
    fi
    rm -f "$pkg.bak"
  fi
done

echo "configured native cc-link-flags: $FLAGS"
if [ -n "$STUB_CFLAGS" ]; then
  echo "configured native stub-cc-flags: $STUB_CFLAGS"
fi
