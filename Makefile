NAME=iris

all: release

debug: FLAGS = -debug
debug: build

release: build

build:
	odin build src -out:${NAME} ${FLAGS}

run: build
	./${NAME} --device-filter="BlackHole 2ch"

clean:
	rm ${NAME}
	rm -r *.dSYM
