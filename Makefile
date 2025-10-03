# Inception-of-Things project automation

.PHONY: help check-env

help:
	@echo "Available targets:"
	@echo "  make check-env    # Inspect the current machine for required tooling"

check-env:
	@./scripts/check_env.sh
