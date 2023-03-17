include lib/options.mk

GIT=git
GIT_USER_NAME = $(shell git config user.name | sed "s/^'\|'$$//g")
GITHUB_USER_NAME ?= $(subst /,,$(dir $(GITHUB_REPOSITORY)))
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

define git-config-set-user
if [ -z '$(GIT_USER_NAME)' ] && [ -n '$(GITHUB_USER_NAME)' ]; then \
    $(GIT) config user.name '$(GITHUB_USER_NAME)'; \
    $(GIT) config user.email '$(GITHUB_USER_NAME)@users.noreply.github.com'; \
fi
endef

define git-rebase
$(call git-config-set-user); \
$(GIT) rebase '$(1)'
endef

define git-commit
$(call git-config-set-user); \
$(GIT) commit $(1)
endef

define git-stash
$(call git-config-set-user); \
$(GIT) stash $(1)
endef

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
		$(GIT) branch | grep ' $(1)$$' --silent \
		|| $(GIT) branch '$(1)' '$(GIT_BRANCH_CONTENT)'; \
		$(GIT) checkout '$(1)'; \
	fi
endef

ifeq (1,$(GIT_COMMIT))
define git-commit-path
	$(GIT) status --untracked-files=all --porcelain $(1) \
	| grep '.' --silent \
	&& { \
		$(GIT) add $(1) \
		&& $(call git-config-set-user) \
		&& $(GIT) commit -m '$(2)' \
	; } \
	|| true; \
	if [ "$(GIT_PUSH)" = 1 ]; then \
		$(GIT) push '$(GIT_REMOTE_CONTENT)' '$(GIT_BRANCH_CONTENT)'; \
	fi
endef
else
define git-commit-path
echo >/dev/null
endef
endif

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
		"$(GIT)" fetch '$(GIT_REMOTE_CONTENT)'; \
		"$(GIT)" rebase "'$(GIT_REMOTE_CONTENT)'/$(1)"; \
	fi
endef

define git-pluck-file
	$(GIT) fetch '$(1)'
	$(GIT) checkout '$(1)/$(2)' -- '$(3)'
	$(GIT) mv '$(3)' '$(4)'
endef

.PHONY: git-cleanup-uploads
git-cleanup-uploads:  ### Cleanup the uploads branch
	$(GIT) fetch --prune '$(GIT_REMOTE_UPLOAD)'
	$(call git-stash,) || true
	$(GIT) checkout -B '$(GIT_BRANCH_UPLOAD)' '$(GIT_REMOTE_UPLOAD)/$(GIT_BRANCH_UPLOAD)'
ifdef $(EPISODE_ATTACHMENT)
	$(GIT) rm '$(GIT_DIR_UPLOAD)/$(EPISODE_ATTACHMENT)'
	$(call git-commit,-m 'chore: remove used attachment')
endif
ifdef $(EPISODE_ARTWORK)
	$(GIT) rm '$(GIT_DIR_UPLOAD)/$(EPISODE_ARTWORK)'
	$(call git-commit,-m 'chore: remove used artwork')
endif
	$(GIT) reset --soft '$(GIT_REMOTE_STATIC)/$(GIT_BRANCH_STATIC)'
	$(GIT) add '$(GIT_DIR_UPLOAD)'
	$(call git-commit,-m 'chore: squash uploads')
	$(GIT) push --force '$(GIT_REMOTE_UPLOAD)' '$(GIT_BRANCH_UPLOAD)'
	$(GIT) checkout '$(GIT_BRANCH_CURRENT)'
	$(call git-stash,pop) || true
