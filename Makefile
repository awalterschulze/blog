serve:
	hugo server -w --buildDrafts --enableGitInfo

generate:
	hugo --cleanDestinationDir --enableGitInfo

newpost:
	echo "hugo new post/<postname>.md"

update:
	brew upgrade hugo
	git submodule update --recursive --remote
