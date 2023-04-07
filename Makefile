INFO := "4.7 update accelerate"


all: add commit push
		

add:
		git add .

commit:
		git commit -m ${INFO}

push:
		git push origin main
