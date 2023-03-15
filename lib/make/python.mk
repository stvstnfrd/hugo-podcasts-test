PYTHON_VENV=./.venv
PYTHON_VENV_BIN=$(PYTHON_VENV)/bin
PYTHON_LIB_PATH=./lib
PYTHON_LIB=PYTHONPATH=$(PYTHON_LIB_PATH)
PYTHON=$(PYTHON_LIB) $(PYTHON_VENV_BIN)/python
PYTHON_REQUIREMENTS_INPUT=./lib/requirements.txt
PYTHON_REQUIREMENTS_OUTPUT_DIRECTORY=tmp
PYTHON_REQUIREMENTS_OUTPUT=$(PYTHON_REQUIREMENTS_OUTPUT_DIRECTORY)/$(notdir $(PYTHON_REQUIREMENTS_INPUT))
PIP=$(PYTHON_VENV_BIN)/pip
PIP_INSTALL=$(PIP) install

define fetch-feeds
$(PYTHON) bin/parse-feed.py '$(1)' \
	--content-directory '$(2)' \
	--static-directory '$(3)' \
	$(4) \
;
endef

.PHONY: requirements-python
requirements-python: $(PYTHON_REQUIREMENTS_OUTPUT) requirements-system  ### Create a new virtualenv and install packages
$(PYTHON_REQUIREMENTS_OUTPUT): $(PYTHON_REQUIREMENTS_INPUT)
	echo $(PYTHON_REQUIREMENTS_INPUT)
	test -d '$(PYTHON_VENV)' || python3 -m venv '$(PYTHON_VENV)'
	$(PIP) install -r "$(PYTHON_REQUIREMENTS_INPUT)"
	test -d '$(PYTHON_REQUIREMENTS_OUTPUT_DIRECTORY)' || mkdir '$(PYTHON_REQUIREMENTS_OUTPUT_DIRECTORY)'
	cp '$(<)' '$(@)'

.PHONY: content
content: requirements-python  ## Update content/metadata for feeds
	$(call assert-not-has-changes-saved,)
	$(call assert-not-has-changes-to-file,dist/content)
	$(call git-checkout-branch,$(GIT_BRANCH_CONTENT))
	$(call git-fetch,$(GIT_BRANCH_CONTENT))
	$(call fetch-feeds,./dist,content/content,static/static,--skip-images --skip-media)
	$(call git-commit-path,dist/content,feat: update content)

.PHONY: static
static: requirements-python  ## Fetch static assets (images/audio/video)
	$(call assert-not-has-changes-saved,)
	$(call assert-not-has-changes-to-file,dist/static)
	$(call git-checkout-branch,$(GIT_BRANCH_STATIC))
	$(call git-fetch,$(GIT_BRANCH_STATIC))
ifeq (1,$(GIT_COMMIT))
	"$(GIT)" merge --no-ff -m 'feat: pull in content changes' "$(GIT_BRANCH_CONTENT)"
endif
	$(call fetch-feeds,./dist,content/content,static/static)
	$(call git-commit-path,dist/static,feat: update static)

.PHONY: update-feeds
update-feeds: requirements-python
	$(PYTHON) bin/parse-opml.py "$(OPML_FILE)" dist --content-directory content/content
