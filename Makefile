
build:
	rm -rf dist && hugo

tos3:
	aws s3 sync public/ s3://blog2023.tonychoucc.com \
		--delete \
		--exclude ".DS_Store" \
		--profile tonychoucc

deploy-s3: build tos3

dev:
	hugo server -D

purge:
	aws cloudfront create-invalidation \
		--distribution-id E3TA028L5M59A6 \
		--paths "/*" \
		--profile tonychoucc

.PHONY:
	build tos3 deploy-s3 dev
