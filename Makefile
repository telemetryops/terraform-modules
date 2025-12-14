# Git-only Makefile - CI/CD handles all builds
# No local builds needed - everything runs in GitHub Actions

.PHONY: commit amend push

# Commit all changes with message
commit:
	@if [ -z "$(MSG)" ]; then \
		echo "Error: MSG parameter required. Use: make commit MSG=\"your message\""; \
		exit 1; \
	fi; \
	git add .; \
	git commit -m "$(MSG)"; \
	git push origin $$(git branch --show-current)

# Amend last commit with new message
amend:
	@if [ -z "$(MSG)" ]; then \
		echo "Error: MSG parameter required. Use: make amend MSG=\"your message\""; \
		exit 1; \
	fi; \
	git add .; \
	git commit --amend -m "$(MSG)"; \
	git push origin $$(git branch --show-current) --force-with-lease

# Push current branch
push:
	git push origin $$(git branch --show-current)
