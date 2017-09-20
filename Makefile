servedrafts:
	hugo server -w --buildDrafts

generate:
	hugo --cleanDestinationDir

serve:
	hugo server -w

newpost:
	echo "hugo new post/<postname>.md"

