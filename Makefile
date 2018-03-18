serve:
	hugo server -w --buildDrafts

generate:
	hugo --cleanDestinationDir

newpost:
	echo "hugo new post/<postname>.md"

update:
	brew upgrade hugo
	git submodule update --recursive --remote
