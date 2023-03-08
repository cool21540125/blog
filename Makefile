
.PHONY: dev
dev:
	hugo server

.PHONY: build
build:
	hugo -v

.PHONY: nginx
nginx:
	rm -rf public && \
	hugo && \
	docker run -p 80:80 -d --name blog-nginx -v "${PWD}/public:/usr/share/nginx/html/" nginx:alpine

.PHONY: clean
clean:
	rm -rf public && docker rm -f blog-nginx
