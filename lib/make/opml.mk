OPML_FILE=etc/feed.opml
OPML_FILE_BACKUP=$(OPML_FILE).bak
OPML_UPDATE_SCRIPT=./bin/opml-add-feed.awk
OPML_DATE=$(shell date +'%b %-d, %Y %H:%M:%S')
ifndef OPML_TITLE
OPML_TITLE=$(OPML_URL)
endif

.PHONY: subscribe
subscribe: requirements-system  ## Subscribe to a new feed
ifndef OPML_URL
	@echo "Usage: make subscribe OPML_URL='https://.../index.xml' OPML_TITLE='...' OPML_WEBSITE='https://.../index.html'"
	exit 1
else
	cp "$(OPML_FILE)" "$(OPML_FILE_BACKUP)"
	awk \
		-f '$(OPML_UPDATE_SCRIPT)' \
		-v date='$(OPML_DATE)' \
		-v title='$(OPML_TITLE)' \
		-v website='$(OPML_WEBSITE)' \
		-v feed='$(OPML_URL)' \
		"$(OPML_FILE_BACKUP)" \
	>"$(OPML_FILE)"
	rm "$(OPML_FILE_BACKUP)"
	$(call git-commit-path,$(OPML_FILE),feat: subscribe to new feed; $(OPML_TITLE))
endif
