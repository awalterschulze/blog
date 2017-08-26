servedrafts:
	hugo server -w --buildDrafts

generate:
	hugo

serve:
	hugo server -w

newpost:
	echo "hugo new post/<postname>.md"

