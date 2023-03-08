# Fetch static assets and place them on a separate branch
# and/or another remote
# GIT_BRANCH_STATIC=static
# GIT_REMOTE_STATIC=upstream

options_advanced:  ## Read and edit lib/options.mk before running this!
	git checkout "$(GIT_BRANCH_CONTENT)"
	git fetch "$(GIT_REMOTE_CONTENT)"
	git rebase "$(GIT_REMOTE_CONTENT)/$(GIT_BRANCH_CONTENT)"
	git push "$(GIT_REMOTE_CONTENT)" \
		--set-upstream \
		"$(GIT_BRANCH_CONTENT)" \
	;
	git fetch "$(GIT_REMOTE_STATIC)"
	git branch \
		"$(GIT_BRANCH_STATIC)" \
		"$(GIT_BRANCH_CONTENT)" \
	|| true
	;
	git push "$(GIT_REMOTE_STATIC)" \
		--set-upstream \
		"$(GIT_BRANCH_STATIC)" \
	;
