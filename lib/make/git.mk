include lib/options.mk

GIT=git
GIT_REMOTE_CONTENT ?= origin
GIT_BRANCH_CONTENT ?= $(if $(shell git rev-parse $(GIT_REMOTE_CONTENT)/master >/dev/null 2>&1 && echo 1),master,main)
ifndef GIT_BRANCH_STATIC
GIT_BRANCH_STATIC=$(GIT_BRANCH_CONTENT)
endif
ifndef GIT_REMOTE_STATIC
GIT_REMOTE_STATIC=$(GIT_REMOTE_CONTENT)
endif
GIT_REMOTE_UPLOAD ?= $(GIT_REMOTE_STATIC)
GIT_BRANCH_UPLOAD ?= uploads
GIT_DIR_UPLOAD ?= dist/uploads
GIT_BRANCH_CURRENT=$(shell $(GIT) branch --show-current)
# Set these to a non-empty value to:
## Commit changes made by the target
ifndef GIT_COMMIT
GIT_COMMIT=
endif
## Push commits to the remote repository
ifndef GIT_PUSH
GIT_PUSH=
endif
ifndef GIT_FETCH
GIT_FETCH=
endif
ifndef GIT_BRANCH
GIT_BRANCH=
endif

define assert-not-has-changes-saved
@$(GIT) diff --cached --exit-code --quiet . \
|| { \
    echo "Canceling; local changes staged for commit."; \
    exit 1; \
}
endef

define assert-not-has-changes-to-file
$(GIT) status --untracked-files=no --porcelain $(1) \
| grep '.' --silent \
&& { \
    $(GIT) status --untracked-files=no "$(1)"; \
    echo "Canceling; local changes to commit."; \
    exit 1; \
} \
|| true
endef

define git-checkout-branch
	if [ "$(GIT_BRANCH)" = 1 ]; then \
		$(GIT) branch | grep " $(1)$$" --silent \
		|| $(GIT) branch "$(1)" "main"; \
		$(GIT) checkout "$(1)"; \
	fi
endef

define git-commit-path
	if [ "$(GIT_COMMIT)" = 1 ]; then \
		"$(GIT)" status --untracked-files=all --porcelain $(1) \
		| grep '.' --silent \
		&& { \
			$(GIT) add $(1) \
			&& $(GIT) commit -m '$(2)' \
		; } \
		|| true; \
		if [ "$(GIT_PUSH)" = 1 ]; then \
			$(GIT) push origin "$(GIT_BRANCH_CONTENT)"; \
		fi \
	fi
endef

.PHONY: git-branch-on-remote-uploads
git-branch-on-remote-uploads: .git/refs/remotes/$(GIT_REMOTE_UPLOAD)/$(GIT_BRANCH_UPLOAD)
.git/refs/remotes/$(GIT_REMOTE_UPLOAD)/$(GIT_BRANCH_UPLOAD):
	$(GIT) fetch '$(GIT_REMOTE_UPLOAD)' || true
	if [ ! -e '$(@)' ]; then \
		$(GIT) branch '$(GIT_BRANCH_UPLOAD)' '$(GIT_REMOTE_STATIC)/$(GIT_BRANCH_STATIC)'; \
		$(GIT) push '$(GIT_REMOTE_UPLOAD)' '$(GIT_BRANCH_UPLOAD)'; \
	fi


define git-fetch
	if [ "$(GIT_FETCH)" = 1 ]; then \
		"$(GIT)" fetch origin; \
		"$(GIT)" rebase "origin/$(1)"; \
	fi
endef
