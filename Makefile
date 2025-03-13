NAME=iris

all: release

debug: FLAGS = -debug
debug: build

release: build

build:
	mkdir -p ./out && odin build src -out:out/${NAME} ${FLAGS}

run: build
	./out/${NAME} --device-filter="BlackHole 2ch"

clean:
	rm ${NAME}
	rm -r *.dSYM
