INFO := "4.7 update testbench pe3x3"


all: add commit push
		

add:
		git add .

commit:
		git commit -m ${INFO}

push:
		git push origin main
