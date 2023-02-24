
.PHONY: s3
s3:
	aws s3 sync public/ s3://blog2.tonychoucc.com \
		--delete \
		--exclude ".DS_Store" \
		--profile tonychoucc


.PHONY: dev
dev:
	hugo server -D


.PHONE: nginx
nginx:
	rm -rf public && \
	hugo && \
	docker run -p 80:80 --rm -v "$(pwd)/public:/usr/share/nginx/html/" nginx:alpine


.PHONY: purge
purge:
	aws cloudfront create-invalidation \
		--distribution-id "E31VLMVJPNIG00" \
		--paths "/*" \
		--profile tonychoucc
