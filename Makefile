.PHONY: serve build deploy clean install lint rebuild

# Variables
SITE_DIR = site
DOCS_DIR = docs

# Install dependencies
install:
	python -m pip install -e ".[dev]"

# Serve locally with live reload
serve:
	mkdocs serve

# Build static site
build:
	mkdocs build --clean

# Deploy to GitHub Pages
deploy:
	mkdocs gh-deploy --force

# Clean build artifacts
clean:
	rm -rf $(SITE_DIR) .cache

# Check for broken links
lint:
	mkdocs build --strict 2>&1 || true
	@echo "Check for any warnings above"

# Full rebuild
rebuild: clean build
