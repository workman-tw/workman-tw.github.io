# Marp slide operations

# Interactive slide operation selector
slide:
	@./scripts/interactive.sh \
		"Build all slides::just slide-build" \
		"Build intro slide::just slide-build-intro"

# Build all Marp slides to PPTX
slide-build:
	@./scripts/slide/build.sh

# Build intro slide to PPTX
slide-build-intro:
	@./scripts/slide/build.sh docs/slides/intro
