ifneq (,$(GITHUB_USER_NAME))
COVER_IMAGE=$(wildcard src/content/cover.*)
ifeq (1,$(COVER_IMAGE_FORCE))
COVER_IMAGE=
endif
GITHUB_USER_IMAGE=https://github.com/$(GITHUB_USER_NAME)
TMP_USER_IMAGE=$(TMP)/cover

.PHONY: github-profile-image
github-user-image:
ifeq (,$(COVER_IMAGE))
	echo $(COVER_IMAGE)
	$(call assert-not-has-changes-saved)
	$(call assert-not-has-changes-to-file,src/content/cover.jpg src/content/cover.jpg)
	test -d '$(TMP)' || mkdir '$(TMP)'
	test -d 'src/content' || mkdir 'src/content'
	curl -L '$(GITHUB_USER_IMAGE).jpg' -o '$(TMP_USER_IMAGE).jpg'
	if [ '100' -gt "$$(du --bytes '$(TMP_USER_IMAGE).jpg' | awk '{print $$1}')" ]; then \
		rm '$(TMP_USER_IMAGE).jpg' || true; \
		curl -L '$(GITHUB_USER_IMAGE).png' -o '$(TMP_USER_IMAGE).png'; \
		if [ '100' -gt "$$(du --bytes '$(TMP_USER_IMAGE).png' | awk '{print $$1}')" ]; then \
			echo 'No Image Found!'; \
			rm '$(TMP_USER_IMAGE).png' || true; \
			exit 1; \
		else \
			mv '$(TMP_USER_IMAGE).png' src/content/cover.png; \
			$(call git-commit-path,src/content/cover.png,chore: update logo from github avatar); \
		fi; \
	else \
		mv '$(TMP_USER_IMAGE).jpg' src/content/cover.jpg; \
		$(call git-commit-path,src/content/cover.jpg,chore: update logo from github avatar); \
	fi; \

else
	@echo "Refusing to overwrite existing file"
	@echo "Re-run with COVER_IMAGE_FORCE=1;"
	@echo "    make $(@) COVER_IMAGE_FORCE=1"
endif
endif
