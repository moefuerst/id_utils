COMPOSE      = docker compose -f oci/compose-dev.yml
COMPOSE_TEST = docker compose -f oci/compose-test.yml
RUN          = $(COMPOSE) run --rm dev
RUN_TEST     = $(COMPOSE_TEST) run --rm test

.PHONY: help dev dev.clean deps compile precommit check test test.ci test.clean test.deps

help: ## Show available targets
	@grep -E '^[a-zA-Z_.-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-16s %s\n", $$1, $$2}'

dev: ## Drop into an interactive shell inside the dev container
	$(RUN) bash

dev.clean: ## Remove dev container and cached build volumes
	$(COMPOSE) down --volumes --remove-orphans

deps: ## Install dependencies
	$(RUN) sh -c "mix deps.get --check-locked && mix deps.compile"

compile: ## Compile the project
	$(RUN) mix compile

docs: ## Generate code documentation
	$(RUN) mix docs

precommit: ## Run code quality checks
	$(RUN_TEST) mix precommit

check: ## Run code audit
	$(RUN_TEST) mix check

test: ## Run the test suite
	$(RUN_TEST) mix test

test.ci: ## Run the test suite + mutation testing
	$(RUN_TEST) sh -c "mix deps.get --check-locked && mix test.ci"

test.clean: ## Remove test container + cached build volumes
	$(COMPOSE_TEST) down --volumes --remove-orphans

test.deps: ## Install test dependencies
	$(RUN_TEST) sh -c "mix deps.get --check-locked && mix deps.compile"
