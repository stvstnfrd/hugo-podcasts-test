.PHONY: help
help:  ## This.
	@perl -ne 'print if /^[a-zA-Z.-]+:.*## .*$$/' $(MAKEFILE_LIST) \
	| sort \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

include lib/make/hugo.mk
include lib/make/opml.mk
include lib/make/git.mk
include lib/make/python.mk
include lib/make/test.mk
include lib/make/requirements.mk
