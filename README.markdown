# hugo-podcasts

aka rss2hugo

## Use

### For your first use/podcast

1.  [Fork](https://github.com/stvstnfrd/hugo-podcasts/fork)
    this repository.
    [^fork-a-repo]
2.  Mark the new repository as a template.
    [^create-template-repo]

### For each use/podcast

1.  [Create](https://github.com/new) a new repository.
    [^create-from-template]
    - From the _Repository template_ dropdown,
      select the repository you forked in the first step.
2.  Edit the list of feeds in `./etc/feeds.opml`.
3.  Refresh your content
    - `make update-content`
4.  If you're also saving the artwork/media,
    - Refresh your static assets
        - `make update-static`
5.  Rebuild the static site.
    - `make build`
6.  Publish your site
    - `ls dist/public`

### Advanced Use

#### Store static on another branch

Edit `lib/options.mk`:

```Makefile
# Set this to the branch where you want to store static content
GIT_BRANCH_STATIC=static
```

Then run this _once_ in the terminal:

```sh
make options_advanced
```

#### Store static on another remote repository

Edit `lib/options.mk`:

```Makefile
# Set this to the remote where you want to store static content
GIT_REMOTE_STATIC=upstream
```

Then run this _once_ in the terminal:

```sh
# URL is the remote repository,
#     eg: git@github.com:user/project.git
git remote add upstream URL
git fetch upstream
make options_advanced
```

#### Store static on another remote _and_ branch

Follow the steps above (for separate remotes and branches):

- Edit `lib/options.mk` to update both variables
- Run the shell commands from the `Remote` section;
    - you don't need to run the `Branch` section.


# References

[^create-template-repo]: ["Creating a template repository"](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-template-repository)
[^fork-a-repo]: ["Fork a repo"](https://docs.github.com/en/get-started/quickstart/fork-a-repo)
[^create-from-template]: ["Creating a repository from a template"](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template)
