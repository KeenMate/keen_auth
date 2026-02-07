.PHONY: setup dev clean deps compile test routes

# Setup the project (first time)
setup: deps
	@echo "✓ Setup complete! Run 'make dev' to start the server"

# Start development server
dev:
	mix phx.server

# Interactive console
iex:
	iex -S mix phx.server

# Get dependencies
deps:
	mix deps.get

# Compile the project
compile:
	mix compile

# Clean build artifacts
clean:
	mix clean
	rm -rf _build deps

# Run tests
test:
	mix test

# Show routes
routes:
	mix phx.routes

# Format code
format:
	mix format

# Help
help:
	@echo "Available targets:"
	@echo "  setup   - Install dependencies (first time setup)"
	@echo "  dev     - Start development server"
	@echo "  iex     - Start server with interactive console"
	@echo "  deps    - Get dependencies"
	@echo "  compile - Compile the project"
	@echo "  clean   - Clean build artifacts"
	@echo "  test    - Run tests"
	@echo "  routes  - Show all routes"
	@echo "  format  - Format code"
