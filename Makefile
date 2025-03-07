NAME=iris

all: release

debug: FLAGS = -debug
debug: build

release: build

build:
	odin build src -out:${NAME} ${FLAGS}

clean:
	rm ${NAME}
	rm -r *.dSYM
