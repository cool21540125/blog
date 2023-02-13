
.PHONY: build
build:
	rm -rf public && hugo


.PHONY: s3
s3:
	aws s3 sync public/ s3://blog.tonychoucc.com \
		--delete \
		--exclude ".DS_Store" \
		--profile tonychoucc


.PHONY: dev
dev:
	hugo server -D


.PHONY: purge
purge:
	aws cloudfront create-invalidation \
		--distribution-id "E31VLMVJPNIG00" \
		--paths "/*" \
		--profile tonychoucc
