serve:
	hugo server -w --buildDrafts --enableGitInfo

generate:
	hugo --cleanDestinationDir --enableGitInfo

newpost:
	echo "hugo new post/<postname>.md"

update:
	brew upgrade hugo || true
	git submodule update --recursive --remote

install:
	brew install hugo