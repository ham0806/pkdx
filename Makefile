# Local test/check entry points.
#
# CI intentionally runs little automatically (see .github/workflows/). Run
# `make test` locally before pushing. See README「ローカルでのテスト実行」.

.PHONY: test check moon-test moon-build site-test site-check

# Full local verification: everything CI used to run on PRs, plus the MoonBit
# native test suite.
test: moon-test site-test

# Compile pass only (no test execution). Faster than `make test`.
check: moon-build site-check

# `moon test` needs real BLAS symbols on Linux/Windows (see setup.sh step 2.7
# and scripts/configure_native_link_flags.sh). The flag rewrite touches the
# tracked file src/payoff/moon.pkg, so a pre-run snapshot is restored
# afterwards to keep the working tree clean and preserve any local edits
# (vendored .mooncakes/ rewrites are left; gitignored).
# Note: `moon check` is NOT used — it also type-checks vendored deps'
# `test {}` blocks, which fail on newer toolchains.
moon-test:
	moon update
	@cp src/payoff/moon.pkg src/payoff/moon.pkg.makebak
	@status=0; \
	bash scripts/configure_native_link_flags.sh && \
		moon test --target native || status=$$?; \
	mv src/payoff/moon.pkg.makebak src/payoff/moon.pkg; \
	exit $$status

moon-build:
	moon update
	@cp src/payoff/moon.pkg src/payoff/moon.pkg.makebak
	@status=0; \
	bash scripts/configure_native_link_flags.sh && \
		moon build --target native src/main || status=$$?; \
	mv src/payoff/moon.pkg.makebak src/payoff/moon.pkg; \
	exit $$status

site-test:
	cd site && bun install --frozen-lockfile
	cd site && bun test
	cd site && bun run check
	cd site && bun run smoke

site-check:
	cd site && bun install --frozen-lockfile
	cd site && bun run check
