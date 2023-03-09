GIT=git
HUGO=hugo
HUGO_FLAGS=--buildDrafts --cacheDir=$(PWD)/tmp/cache
HUGO_SITE_NAME=src
HUGO_THEME=$(shell $(PYTHON) ./bin/get-key-from-yaml.py $(HUGO_SITE_NAME)/config.yaml theme)
HUGO_CONFIG_FILE=$(HUGO_SITE_NAME)/config.yaml
PYTHON=PYTHONPATH=./lib ./.venv/bin/python
PYTHON_REQUIREMENTS=./lib/requirements.txt
PYLINT=PYTHONPATH=./lib ./.venv/bin/pylint
COVERAGE=PYTHONPATH=./lib ./.venv/bin/coverage
GIT_REMOTE_CONTENT=origin

.PHONY: help
help:  ## This.
	@perl -ne 'print if /^[a-zA-Z.-]+:.*## .*$$/' $(MAKEFILE_LIST) \
	| sort \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: _virtualenv
_virtualenv:  ## Create a new virtualenv and install packages
	test -d ./.venv || python3 -m venv ./.venv
	./.venv/bin/pip install -r "$(PYTHON_REQUIREMENTS)"

.PHONY: serve
serve:  ## Serve up a preview instance of the site
	cd "$(HUGO_SITE_NAME)" && \
		"$(HUGO)" server $(HUGO_FLAGS)

.PHONY: build
build:  ## Build the Hugo site
	cd "$(HUGO_SITE_NAME)" \
		&& $(HUGO) mod get -u "$(HUGO_THEME)" \
		&& "$(HUGO)" $(HUGO_FLAGS) \
	;

init:  ## Initialize an empty repository
	"$(HUGO)" new site "$(HUGO_SITE_NAME)"
	echo "podcasts: {}" >> "$(HUGO_CONFIG_FILE)"
	mkdir -p dist/content
	mkdir -p dist/static


include lib/make/opml.mk
include lib/options.mk
GIT_IS_ACTIVE=$(shell "$(GIT)" rev-parse HEAD 2>/dev/null >/dev/null && echo 1 || echo 0)
GIT_HAS_ORIGIN=$(shell "$(GIT)" remote get-url origin 2>/dev/null >/dev/null && echo 1 || echo 0)
GIT_CAN_AUTHOR=$(shell "$(GIT)" config user.email 2>/dev/null >/dev/null && echo 1 || echo 0)
ifndef GIT_BRANCH_CONTENT
GIT_BRANCH_CONTENT=main
endif
ifndef GIT_BRANCH_STATIC
GIT_BRANCH_STATIC=$(GIT_BRANCH_CONTENT)
endif
ifndef GIT_REMOTE_STATIC
GIT_REMOTE_STATIC=$(GIT_REMOTE_CONTENT)
endif
GIT_BRANCH_CURRENT=$(shell $(GIT) branch --show-current)
# Set these to a non-empty value to:
## Commit changes made by the target
GIT_COMMIT=
## Push commits to the remote repository
GIT_PUSH=
GIT_FETCH=
GIT_BRANCH=

.PHONY: update-theme
update-theme:  ## Check for and download new versions of the Hugo Theme
	@if ! $(GIT) diff --cached --exit-code . 2>/dev/null >/dev/null; then \
		$(GIT) diff --cached; \
		echo "Canceling; local changes staged for commit."; \
		exit 1; \
	fi
	@if ! $(GIT) diff --exit-code src/go.mod src/go.sum 2>/dev/null >/dev/null; then \
		$(GIT) diff src/go.mod src/go.sum; \
		echo "Canceling; local changes to commit."; \
		exit 1; \
	fi
	cd "$(HUGO_SITE_NAME)" && \
		"$(HUGO)" mod get -u github.com/frjo/hugo-theme-zen \
		&& "$(HUGO)" mod tidy;
ifeq (1,$(GIT_IS_ACTIVE))
	$(GIT) add src/go.mod src/go.sum
	$(GIT) commit -m 'chore: bump theme versions' || true
endif

define assert-not-has-changes-saved
@$(GIT) diff --cached --exit-code --quiet . \
|| { \
    echo "Canceling; local changes staged for commit."; \
    exit 1; \
}
endef

define assert-not-has-changes-to-file
$(GIT) status --untracked-files=no --porcelain "$(1)" \
| grep '.' --silent \
&& { \
    $(GIT) status --untracked-files=no "$(1)"; \
    echo "Canceling; local changes to commit."; \
    exit 1; \
} \
|| true
endef

.PHONY: update-content
update-content:  ## Update content/metadata for feeds
ifeq (1,$(GIT_IS_ACTIVE))
	$(call assert-not-has-changes-saved,)
	$(call assert-not-has-changes-to-file,dist/content)
ifeq (1,$(GIT_BRANCH))
	$(GIT) branch | grep " $(GIT_BRANCH_CONTENT)$$" --silent \
	|| $(GIT) branch "$(GIT_BRANCH_CONTENT)" "main"
	"$(GIT)" checkout "$(GIT_BRANCH_CONTENT)"
endif
ifeq (1,$(GIT_FETCH))
	"$(GIT)" fetch origin
	"$(GIT)" rebase "origin/$(GIT_BRANCH_CONTENT)"
endif
endif
	$(PYTHON) bin/parse-opml.py "$(OPML_FILE)" dist --content-directory content/content
	$(PYTHON) bin/parse-feed.py ./dist \
		--skip-images \
		--skip-media \
		--content-directory content/content \
		--static-directory static/static \
	;
ifeq (1,$(GIT_COMMIT))
	"$(GIT)" status --untracked-files=all --porcelain dist/content \
	| grep '.' --silent \
	&& { \
		$(GIT) add dist/content \
		&& $(GIT) commit -m 'feat: update content' \
	; } \
	|| true
ifeq (1,$(GIT_PUSH))
	$(GIT) push origin "$(GIT_BRANCH_CONTENT)"
endif
endif

.PHONY: update-static
update-static:  ## Fetch static assets (images/audio/video)
ifeq (1,$(GIT_IS_ACTIVE))
	@if ! $(GIT) diff --cached --exit-code . 2>/dev/null >/dev/null; then \
		$(GIT) diff --cached; \
		echo "Canceling; local changes staged for commit."; \
		exit 1; \
	fi
	"$(GIT)" status --untracked-files=all --porcelain dist/static \
	| grep '.' --silent \
	&& { \
		$(GIT) status --untracked-files=all dist/static; \
		echo "Canceling; local changes to commit."; \
	} \
	|| true
ifeq (1,$(GIT_CAN_AUTHOR))
	$(GIT) branch | grep " $(GIT_BRANCH_STATIC)$$" --silent \
	|| $(GIT) branch "$(GIT_BRANCH_STATIC)" "$(GIT_BRANCH_CONTENT)"
	"$(GIT)" checkout "$(GIT_BRANCH_STATIC)"
ifeq (1,$(GIT_HAS_ORIGIN))
	"$(GIT)" fetch origin
	"$(GIT)" rebase "origin/$(GIT_BRANCH_STATIC)"
endif
	"$(GIT)" merge --no-ff -m 'feat: pull in content changes' "$(GIT_BRANCH_CONTENT)"
endif
endif
	$(PYTHON) bin/parse-opml.py "$(OPML_FILE)" dist --content-directory content/content
	$(PYTHON) bin/parse-feed.py ./dist \
		--content-directory content/content \
		--static-directory static/static \
	;
ifeq (1,$(GIT_CAN_AUTHOR))
	"$(GIT)" status --untracked-files=all --porcelain dist/static \
	| grep '.' --silent \
	&& { \
		$(GIT) add dist/static \
		&& $(GIT) commit -m 'feat: update static' \
	; } \
	|| true
ifeq (1,$(GIT_HAS_ORIGIN))
	"$(GIT)" status --untracked-files=all --porcelain dist/static \
	| grep '.' --silent \
	&& { \
		$(GIT) push origin "$(GIT_BRANCH_STATIC)" \
	; } \
	|| true
endif
endif

.PHONY: lint-python
lint-python:  ## Lint python code for consistency
	$(PYLINT) lib/ --disable fixme

.PHONY: lint-todo
lint-todo:  ## Check for TODO items
	$(PYLINT) lib/ --disable all --enable fixme

.PHONY: lint-hugo
lint-hugo:  ## Check that the Hugo documents build
	$(MAKE) build

.PHONY: lint-xml
lint-xml:  ## Check that the OPML file is valid
	xmllint --noout "$(OPML_FILE)"

.PHONY:
test-python:  ## Check that the python test suite passes
	$(COVERAGE) run -m unittest discover lib/
	$(COVERAGE) report
