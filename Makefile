# LINKLIAN Mobile - Makefile (Flutter only)
# ใช้ได้ทั้ง local dev และ GitHub Actions

SHELL := /bin/bash

.PHONY: help deps format analyze lint test sca ci

help:
	@echo ""
	@echo "Available commands:"
	@echo "  make deps      - flutter pub get"
	@echo "  make format    - dart format (lib/test only, fail if changed)"
	@echo "  make analyze   - flutter analyze"
	@echo "  make lint      - alias of analyze"
	@echo "  make test      - flutter test --coverage"
	@echo "  make sca       - dependency checks (outdated, deps, optional audit)"
	@echo "  make ci        - run all checks (deps -> format -> analyze -> test -> sca)"
	@echo ""

deps:
	flutter pub get

format: deps
	dart format --set-exit-if-changed lib test

analyze: deps
	flutter analyze

lint: analyze

test: deps
	flutter test --coverage
	@test -f coverage/lcov.info && echo "✅ coverage generated" || echo "⚠️ coverage not found"

sca: deps
	flutter pub outdated || true
	flutter pub deps || true
	@flutter pub audit --help >/dev/null 2>&1 && flutter pub audit || echo "⚠️ pub audit not available -> skip"

ci: deps format analyze test sca
	@echo ""
	@echo "✅ All CI checks passed (make ci)"
