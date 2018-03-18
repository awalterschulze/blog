servedrafts:
	hugo server -w --buildDrafts

generate:
	hugo --cleanDestinationDir

serve:
	hugo server -w

newpost:
	echo "hugo new post/<postname>.md"

update:
	brew upgrade hugo
	git submodule update --recursive --remote
