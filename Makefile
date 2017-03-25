GULP := ./node_modules/.bin/gulp

all: build

build:
	$(GULP)

clean:
	rm -rf node_modules

.PHONY: build clean
