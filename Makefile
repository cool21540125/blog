
.PHONY: build
build:
	rm -rf public && hugo


.PHONY: tos3
tos3:
	aws s3 sync public/ s3://blog2023.tonychoucc.com \
		--delete \
		--exclude ".DS_Store" \
		--profile tonychoucc


.PHONY: dev
dev:
	hugo server -D


.PHONY: purge
purge:
	aws cloudfront create-invalidation \
		--distribution-id "ESDXSGFLLAWF7" \
		--paths "/*" \
		--profile tonychoucc
