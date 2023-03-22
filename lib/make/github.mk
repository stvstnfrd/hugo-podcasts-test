ifneq (,$(GITHUB_USER_NAME))
COVER_IMAGE ?= $(wildcard $(HUGO_SITE_NAME)/content/cover.*)
ifeq (1,$(COVER_IMAGE_FORCE))
COVER_IMAGE=
endif
GITHUB_REPO_NAME ?= $(subst /,,$(notdir $(GITHUB_REPOSITORY)))
GITHUB_USER_IMAGE ?= https://github.com/$(GITHUB_USER_NAME)
TMP_USER_IMAGE ?= $(TMP)/cover
SECTIONS ?= $(wildcard $(HUGO_SITE_CONTENT)/*/)

.PHONY: github-profile-image
github-user-image:
ifeq (,$(COVER_IMAGE))
	$(call assert-not-has-changes-saved)
	$(call assert-not-has-changes-to-file,$(HUGO_SITE_CONTENT_COVER_JPG) $(HUGO_SITE_CONTENT_COVER_PNG))
	test -d '$(TMP)' || mkdir '$(TMP)'
	test -d '$(HUGO_SITE_CONTENT)' || mkdir '$(HUGO_SITE_CONTENT)'
	curl -L '$(GITHUB_USER_IMAGE).jpg' -o '$(TMP_USER_IMAGE).jpg'
	image=''; \
	if [ '100' -gt "$$(du --bytes '$(TMP_USER_IMAGE).jpg' | awk '{print $$1}')" ]; then \
		rm '$(TMP_USER_IMAGE).jpg' || true; \
		curl -L '$(GITHUB_USER_IMAGE).png' -o '$(TMP_USER_IMAGE).png'; \
		if [ '100' -gt "$$(du --bytes '$(TMP_USER_IMAGE).png' | awk '{print $$1}')" ]; then \
			echo 'No Image Found!'; \
			rm '$(TMP_USER_IMAGE).png' || true; \
			exit 1; \
		else \
			mv '$(TMP_USER_IMAGE).png' '$(HUGO_SITE_CONTENT_COVER_PNG)'; \
			image=$(HUGO_SITE_CONTENT_COVER_PNG); \
		fi; \
	else \
		mv '$(TMP_USER_IMAGE).jpg' '$(HUGO_SITE_CONTENT_COVER_JPG)'; \
		image=$(HUGO_SITE_CONTENT_COVER_JPG); \
	fi; \
	if [ -n "$${image}" ]; then \
		for i in $(SECTIONS); do \
			if [ "$(COVER_IMAGE_FORCE)" = '1' ] || ( ! [ -e "$${i}/cover.jpg" ] && ! [ -e "$${i}/cover.png" ] ); then \
				cp "$${image}" "$${i}/"; \
				[ '$(GIT_COMMIT)' != '1' ] || $(GIT) add "$${i}/cover.*"; \
			fi \
		done; \
		$(call git-commit-path,$${image},chore: update logo from github avatar); \
	fi \
	;

else
	@echo "Refusing to overwrite existing file"
	@echo "Re-run with COVER_IMAGE_FORCE=1;"
	@echo "    make $(@) COVER_IMAGE_FORCE=1"
endif
endif
