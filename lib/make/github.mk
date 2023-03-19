ifneq (,$(GITHUB_USER_NAME))
GITHUB_USER_IMAGE=https://github.com/$(GITHUB_USER_NAME)
TMP_USER_IMAGE=$(TMP)/cover

.PHONY: github-profile-image
github-user-image:
	$(call assert-not-has-changes-saved)
	$(call assert-not-has-changes-to-file,src/content/cover.jpg src/content/cover.jpg)
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

endif
