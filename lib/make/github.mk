ifneq (,$(GITHUB_USER_NAME))
COVER_IMAGE=$(wildcard src/content/cover.*)
ifeq (1,$(COVER_IMAGE_FORCE))
COVER_IMAGE=
endif
GITHUB_REPO_NAME ?= $(subst /,,$(notdir $(GITHUB_REPOSITORY)))
GITHUB_USER_IMAGE=https://github.com/$(GITHUB_USER_NAME)
TMP_USER_IMAGE=$(TMP)/cover
SECTIONS=$(wildcard src/content/*/)

.PHONY: github-profile-image
github-user-image:
ifeq (,$(COVER_IMAGE))
	echo $(COVER_IMAGE)
	$(call assert-not-has-changes-saved)
	$(call assert-not-has-changes-to-file,src/content/cover.jpg src/content/cover.jpg)
	test -d '$(TMP)' || mkdir '$(TMP)'
	test -d 'src/content' || mkdir 'src/content'
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
			mv '$(TMP_USER_IMAGE).png' src/content/cover.png; \
			image=src/content/cover.png; \
		fi; \
	else \
		mv '$(TMP_USER_IMAGE).jpg' src/content/cover.jpg; \
		image=src/content/cover.jpg; \
	fi; \
	if [ -n "$${image}" ]; then \
		$(call git-commit-path,$${image},chore: update logo from github avatar); \
		for i in $(SECTIONS); do \
			if ! [ -e "$${i}/cover.jpg" ] && ! [ -e "$${i}/cover.png" ]; then \
				cp "$${image}" "$${i}/"; \
			fi \
		done \
	fi \
	;

else
	@echo "Refusing to overwrite existing file"
	@echo "Re-run with COVER_IMAGE_FORCE=1;"
	@echo "    make $(@) COVER_IMAGE_FORCE=1"
endif
endif
