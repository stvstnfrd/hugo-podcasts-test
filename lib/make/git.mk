include lib/options.mk

GIT=git
GIT_REMOTE_CONTENT=origin
ifndef GIT_BRANCH_CONTENT
GIT_BRANCH_CONTENT=main
endif
ifndef GIT_BRANCH_STATIC
GIT_BRANCH_STATIC=$(GIT_BRANCH_CONTENT)
endif
ifndef GIT_REMOTE_STATIC
GIT_REMOTE_STATIC=$(GIT_REMOTE_CONTENT)
endif
GIT_BRANCH_CURRENT=$(shell $(GIT) branch --show-current)
# Set these to a non-empty value to:
## Commit changes made by the target
GIT_COMMIT=
## Push commits to the remote repository
GIT_PUSH=
GIT_FETCH=
GIT_BRANCH=

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
ifeq (1,$(GIT_BRANCH))
	$(GIT) branch | grep " $(1)$$" --silent \
	|| $(GIT) branch "$(1)" "main"
	$(GIT) checkout "$(1)"
endif
endef

define git-commit-path
ifeq (1,$(GIT_COMMIT))
	"$(GIT)" status --untracked-files=all --porcelain $(1) \
	| grep '.' --silent \
	&& { \
		$(GIT) add $(1) \
		&& $(GIT) commit -m '$(2)' \
	; } \
	|| true
ifeq (1,$(GIT_PUSH))
	$(GIT) push origin "$(GIT_BRANCH_CONTENT)"
endif
endif
endef

define git-fetch
ifeq (1,$(GIT_FETCH))
	"$(GIT)" fetch origin
	"$(GIT)" rebase "origin/$(1)"
endif
endef
