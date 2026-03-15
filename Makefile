.PHONY: help setup server-start server-test server-console mobile-run

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Install all dependencies
	cd server && bundle install
	@if command -v flutter >/dev/null 2>&1; then cd mobile && flutter pub get; else echo "Flutter SDK not found. Skipping mobile setup."; fi

server-start: ## Start Rails development server
	cd server && bin/dev

server-test: ## Run Rails test suite
	cd server && bundle exec rspec

server-console: ## Open Rails console
	cd server && bin/rails console

mobile-run: ## Run Flutter app
	cd mobile && flutter run
