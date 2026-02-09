# LINKLIAN Mobile - Makefile

SHELL := /bin/bash

.PHONY: help deps format analyze lint test sca ci clean

help:
	@echo ""
	@echo "Available commands:"
	@echo "  make deps      - flutter pub get"
	@echo "  make format    - dart format (lib/test only, fail if changed)"
	@echo "  make analyze   - flutter analyze --no-pub"
	@echo "  make test      - flutter test --no-pub --coverage"
	@echo "  make sca       - dependency checks (outdated, deps, optional audit)"
	@echo "  make clean     - flutter clean + remove .dart_tool"
	@echo "  make ci        - deps -> format -> analyze -> test -> sca"
	@echo ""

deps:
	flutter pub get

format: deps
	dart format --set-exit-if-changed lib test

analyze: deps
	flutter analyze --no-pub

lint: analyze

test: deps
	flutter test --no-pub --coverage
	@test -f coverage/lcov.info && echo "✅ coverage generated" || echo "⚠️ coverage not found"

sca: deps
	flutter pub outdated || true
	flutter pub deps || true
	@flutter pub audit --help >/dev/null 2>&1 && flutter pub audit || echo "⚠️ pub audit not available -> skip"

clean:
	flutter clean
	rm -rf .dart_tool

ci: deps format analyze test sca
	@echo ""
	@echo "✅ All CI checks passed (make ci)"
