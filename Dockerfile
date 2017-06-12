FROM debian:stretch-slim

MAINTAINER NGINX Docker Maintainers "docker-maint@nginx.com"

ENV NGINX_VERSION 1.12.0-1~stretch
ENV NJS_VERSION   1.12.0.0.1.10-1~stretch

RUN apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y gnupg1 \
	&& \
	NGINX_GPGKEY=573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62; \
	found=''; \
	for server in \
		ha.pool.sks-keyservers.net \
		hkp://keyserver.ubuntu.com:80 \
		hkp://p80.pool.sks-keyservers.net:80 \
		pgp.mit.edu \
	; do \
		echo "Fetching GPG key $NGINX_GPGKEY from $server"; \
		apt-key adv --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$NGINX_GPGKEY" && found=yes && break; \
	done; \
	test -z "$found" && echo >&2 "error: failed to fetch GPG key $NGINX_GPGKEY" && exit 1; \
	apt-get remove --purge -y gnupg1 && apt-get -y --purge autoremove && rm -rf /var/lib/apt/lists/* \
	&& echo "deb http://nginx.org/packages/debian/ stretch nginx" >> /etc/apt/sources.list \
	&& apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
						nginx=${NGINX_VERSION} \
						nginx-module-xslt=${NGINX_VERSION} \
						nginx-module-geoip=${NGINX_VERSION} \
						nginx-module-image-filter=${NGINX_VERSION} \
						nginx-module-njs=${NJS_VERSION} \
						gettext-base \
	&& rm -rf /var/lib/apt/lists/*

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html

EXPOSE 8080 8443

RUN chgrp -R 0 /var/cache/nginx
RUN chmod -R g+rw /var/cache/nginx
RUN find /var/cache/nginx -type d -exec chmod g+x {} +

RUN chgrp -R 0 /etc/nginx
RUN chmod -R g+rw /etc/nginx
RUN find /etc/nginx -type d -exec chmod g+x {} +

RUN chgrp -R 0 /usr/share/nginx/html
RUN chmod -R g+rw /usr/share/nginx/html
RUN find /usr/share/nginx/html -type d -exec chmod g+x {} +

RUN chgrp -R 0 /var/run
RUN chmod -R g+rw /var/run
RUN find /var/run -type d -exec chmod g+x {} +

CMD ["nginx", "-g", "daemon off;"]