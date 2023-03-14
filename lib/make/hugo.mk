HUGO=hugo
HUGO_FLAGS=--buildDrafts --cacheDir=$(PWD)/tmp/cache
HUGO_SITE_NAME=src
HUGO_THEME=$(shell $(PYTHON) ./bin/get-key-from-yaml.py $(HUGO_SITE_NAME)/config.yaml theme)
HUGO_CONFIG_FILE=$(HUGO_SITE_NAME)/config.yaml

.PHONY: serve
serve: requirements-system  ## Serve up a preview instance of the site
	cd "$(HUGO_SITE_NAME)" && \
		"$(HUGO)" server $(HUGO_FLAGS)

.PHONY: build
build: requirements-system  ## Build the Hugo site
	cd "$(HUGO_SITE_NAME)" \
		&& $(HUGO) mod get -u "$(HUGO_THEME)" \
		&& "$(HUGO)" $(HUGO_FLAGS) \
	;

init: requirements-system  ### Initialize an empty repository
	"$(HUGO)" new site "$(HUGO_SITE_NAME)"
	echo "podcasts: {}" >> "$(HUGO_CONFIG_FILE)"
	mkdir -p dist/content
	mkdir -p dist/static

.PHONY: update-theme
theme: requirements-system  ## Check for and download new versions of the Hugo Theme
	$(call assert-not-has-changes-saved,)
	$(call assert-not-has-changes-to-file,src/go.mod src/go.sum)
	cd "$(HUGO_SITE_NAME)" && \
		"$(HUGO)" mod get -u github.com/frjo/hugo-theme-zen \
		&& "$(HUGO)" mod tidy;
	$(call git-commit-path,src/go.mod src/go.sum,chore: bump theme versions)

ifdef FEED_ISSUE
FEED_TITLE=$(shell ./bin/get-key-from-issue title '$(FEED_ISSUE)' | sed "s/'/\\'/g")
FEED_TITLE_CLEAN=$(shell ./bin/get-key-from-issue title '$(FEED_ISSUE)' | sed "s/'/\\'/g" | sed 's/^\s\+//; s/\s\+$$//; s/ \+/-/g; s/[^-_a-zA-Z0-9]//g' | tr '[:upper:]' '[:lower:]')
endif
ifdef FEED_TITLE
FEED_TITLE_CLEAN=$(shell echo '$(FEED_TITLE)' | sed "s/'/\\'/g" | sed 's/^\s\+//; s/\s\+$$//; s/ \+/-/g; s/[^-_a-zA-Z0-9]//g' | tr '[:upper:]' '[:lower:]')
FEED_INDEX_NAME=podcasts/$(FEED_TITLE_CLEAN)/_index.markdown
FEED_INDEX=$(HUGO_SITE_NAME)/content/$(FEED_INDEX_NAME)
endif

.PHONY: feed
feed: requirements-system  ## Create a new feed
ifndef FEED_TITLE
	@echo "Usage: make feed FEED_TITLE='My Podcast Name'"
	@echo "Usage: make feed FEED_ISSUE='./path/to/github-issue.markdown'"
	exit 1
else
	test -d '$(HUGO_SITE_NAME)/content/podcasts' || mkdir '$(HUGO_SITE_NAME)/content/podcasts'
	cd '$(HUGO_SITE_NAME)' && \
		hugo new "$(FEED_INDEX_NAME)"
ifdef FEED_ISSUE
	$(PYTHON) ./bin/update-feed-from-issue.py \
		"$(FEED_INDEX)" "$(FEED_ISSUE)"
endif
endif
