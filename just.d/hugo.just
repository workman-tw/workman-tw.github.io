# Hugo development and build commands

default_port := "1313"

# Interactive Hugo operation selector
hugo:
	@./scripts/interactive.sh \
		"Serve (dev server)::just serve" \
		"Build (production)::just build" \
		"New content::just new" \
		"Clean build artifacts::just clean"

# Start Hugo dev server with live reload
serve port=default_port:
	hugo server -D --port {{ port }}

# Build site for production
build:
	hugo --minify
	@echo "Build complete → public/"

# Create new content interactively
new:
	@./scripts/hugo/new-content.sh

# Remove build artifacts (public/ and resources/)
clean:
	@rm -rf public resources/_gen
	@echo "Cleaned public/ and resources/_gen/"
