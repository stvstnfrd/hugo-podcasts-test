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
