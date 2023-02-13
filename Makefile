
build:
	rm -rf dist && hugo

tos3:
	aws s3 sync dist/ s3://blog2.tonychoucc.com --delete --exclude ".DS_Store"

deploy-s3: build tos3

dev:
	hugo server -D

purge:
	aws cloudfront create-invalidation --distribution-id E3TA028L5M59A6 --paths "/*"

.PHONY:
	build tos3 deploy-s3 dev
