HUGO=hugo
HUGO_FLAGS=--buildDrafts --cacheDir=$(PWD)/tmp/cache
ifneq (,$(GITHUB_REPOSITORY))
HUGO_FLAGS+=--baseURL 'https://$(GITHUB_USER_NAME).github.io/$(GITHUB_REPO_NAME)'
endif
HUGO_SITE_NAME=src
HUGO_THEME=$(shell $(PYTHON) ./bin/get-key-from-yaml.py $(HUGO_SITE_NAME)/config.yaml theme)
HUGO_CONFIG_FILE=$(HUGO_SITE_NAME)/config.yaml
EPISODE_TITLE ?= New Episode
TMP ?= ./tmp

.PHONY: serve
serve: requirements-system  ## Serve up a preview instance of the site
	cd "$(HUGO_SITE_NAME)" && \
		"$(HUGO)" server $(HUGO_FLAGS)

.PHONY: build
build: requirements-system  ## Build the Hugo site
	cd "$(HUGO_SITE_NAME)" \
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
FEED_TITLE=$(shell ./bin/get-key-from-issue 'Feed Title' '$(FEED_ISSUE)' | sed "s/'/\\'/g")
FEED_TITLE_CLEAN=$(shell ./bin/get-key-from-issue 'Feed Title' '$(FEED_ISSUE)' | sed "s/'/\\'/g" | sed 's/^\s\+//; s/\s\+$$//; s/ \+/-/g; s/[^-_a-zA-Z0-9]//g' | tr '[:upper:]' '[:lower:]')
EPISODE_ATTACHMENT ?= $(shell ./bin/get-key-from-issue attachment '$(FEED_ISSUE)' | sed "s/'/\\'/g")
EPISODE_ARTWORK ?= $(shell ./bin/get-key-from-issue artwork '$(FEED_ISSUE)' | sed "s/'/\\'/g")
endif
ifdef FEED_TITLE
FEED_TITLE_CLEAN=$(shell echo '$(FEED_TITLE)' | sed "s/'/\\'/g" | sed 's/^\s\+//; s/\s\+$$//; s/ \+/-/g; s/[^-_a-zA-Z0-9]//g' | tr '[:upper:]' '[:lower:]')
FEED_INDEX_NAME=podcasts/$(FEED_TITLE_CLEAN)/_index.markdown
FEED_INDEX=$(HUGO_SITE_NAME)/content/$(FEED_INDEX_NAME)
endif
ifdef EPISODE_TITLE
EPISODE_TITLE_CLEAN=$(shell echo '$(EPISODE_TITLE)' | sed "s/'/\\'/g" | sed 's/^\s\+//; s/\s\+$$//; s/ \+/-/g; s/[^-_a-zA-Z0-9]//g' | tr '[:upper:]' '[:lower:]')
DATE_PATH=$(shell date '+%Y/%m/%d')
EPISODE_INDEX_NAME=podcasts/$(FEED_TITLE_CLEAN)/$(DATE_PATH)/$(EPISODE_TITLE_CLEAN)/index.markdown
EPISODE_INDEX=$(HUGO_SITE_NAME)/content/$(EPISODE_INDEX_NAME)
endif

.PHONY: feed
feed: requirements-python  ## Create a new feed
ifndef FEED_TITLE
	@echo "Usage: make feed FEED_TITLE='My Podcast Name'"
	@echo "Usage: make feed FEED_ISSUE='./path/to/github-issue.markdown'"
	exit 1
else
	$(call assert-not-has-changes-saved,)
	$(call assert-not-has-changes-to-file,dist/content)
	$(call git-checkout-branch,$(GIT_BRANCH_CONTENT))
	$(call git-fetch,$(GIT_BRANCH_CONTENT))
	test -d '$(HUGO_SITE_NAME)/content/podcasts' || mkdir -p '$(HUGO_SITE_NAME)/content/podcasts'
	test -e '$(FEED_INDEX)' \
	|| (cd '$(HUGO_SITE_NAME)' && \
		hugo new "$(FEED_INDEX_NAME)")
ifneq (,$(FEED_ISSUE))
ifneq (,$(FEED_INDEX))
	$(PYTHON) ./bin/update-from-issue "$(FEED_INDEX)" "$(FEED_ISSUE)"
endif
endif
	grep --quiet '^      - $(FEED_TITLE_CLEAN)$$' .github/ISSUE_TEMPLATE/create-entry.yml || ( \
		test -d '$(TMP)' || mkdir '$(TMP)'; \
		./bin/add-feed-to-issue-template .github/ISSUE_TEMPLATE/create-entry.yml '$(FEED_TITLE_CLEAN)' >'$(TMP)/create-entry.yml'; \
		mv '$(TMP)/create-entry.yml' '.github/ISSUE_TEMPLATE/create-entry.yml'; \
		test "$(GIT_COMMIT)" != 1 || \
			git add .github/ISSUE_TEMPLATE/create-entry.yml; \
	)
endif
	$(call git-commit-path,dist/content,feat: update feeds)

.PHONY: episode
episode: requirements-python  ## Create a new episode
ifndef FEED_TITLE
	@echo "Usage: make episode FEED_TITLE='My Podcast Name'" EPISODE_TITLE='My Episode Title'
	@echo "Usage: make episode FEED_ISSUE='./path/to/github-issue.markdown'"
	exit 1
else
	test -d '$(HUGO_SITE_NAME)/content/podcasts' || mkdir -p '$(HUGO_SITE_NAME)/content/podcasts'
	test -e '$(EPISODE_INDEX)' \
	|| (cd '$(HUGO_SITE_NAME)' && \
		hugo new --kind episodes "$(EPISODE_INDEX_NAME)")
ifdef FEED_ISSUE
	$(PYTHON) ./bin/update-from-issue "$(EPISODE_INDEX)" "$(FEED_ISSUE)"
endif
ifneq (,$(EPISODE_ATTACHMENT))
	$(call git-pluck-file,$(GIT_REMOTE_UPLOAD),$(GIT_BRANCH_UPLOAD),$(GIT_DIR_UPLOAD)/$(EPISODE_ATTACHMENT),$(dir $(EPISODE_INDEX))/cover.mp3)
endif
ifneq (,$(EPISODE_ARTWORK))
	$(call git-pluck-file,$(GIT_REMOTE_UPLOAD),$(GIT_BRANCH_UPLOAD),$(GIT_DIR_UPLOAD)/$(EPISODE_ARTWORK),$(dir $(EPISODE_INDEX))/cover$(suffix $(EPISODE_ARTWORK)))
endif
endif
