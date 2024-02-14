
.PHONY: dev
dev:
	hugo server -D

.PHONY: build
build:
	rm -rf public
	hugo --minify -v

.PHONY: clean
clean:
	rm -rf public
