INFO := "4.8 update README"


all: add commit push
		

add:
		git add .

commit:
		git commit -m ${INFO}

push:
		git push origin main
