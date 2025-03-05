FROM debian:bookworm-slim AS builder
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    git \
    gnutls-dev \
    libcurl4-openssl-dev \
    libgnustep-base-dev \
    libldap2-dev \
    libmariadb-dev-compat \
    libmemcached-dev \
    libpq-dev \
    libsodium-dev \
    libssl-dev \
    libxml2-dev \
    libytnef0-dev \
    libzip-dev \
    tzdata \
    && ln -fs /usr/share/zoneinfo/Australia/Adelaide /etc/localtime \
    && dpkg-reconfigure --frontend noninteractive tzdata


WORKDIR /usr/src/app
COPY versions.yaml .
RUN git clone --depth 1 --branch $(grep "sope_git_tag" versions.yaml | cut -d" " -f2) https://github.com/inverse-inc/sope.git \
    && cd sope && ./configure --with-gnustep --disable-debug --enable-strip --enable-mysql && make && make install && cd ..
RUN git clone --depth 1 --branch $(grep "sogo_git_tag" versions.yaml | cut -d" " -f2) https://github.com/inverse-inc/sogo.git \
    && cd sogo && ./configure --disable-debug --enable-strip && make && make install && cd ..


FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    gnustep-base-runtime \
    libcurl4 \
    libldap-2.5-0 \
    libmariadb3 \
    libmemcached-tools \
    libsodium23 \
    libytnef0 \
    libzip4 \
    memcached \
    nginx \
    procps \
    sudo 

COPY --from=builder /usr/local /usr/local
COPY artifacts/sogo-backup.sh /usr/local/share/doc/sogo/
COPY artifacts/sogo.cron /etc/cron.d/
COPY artifacts/sogod.sh /usr/local/bin/
COPY nginx-conf/sites-enabled/sogo-nginx.conf /etc/nginx/sites-enabled/
RUN rm /etc/nginx/sites-enabled/default

RUN echo -e "# SOGo libraries\n/usr/local/lib/sogo" > /etc/ld.so.conf.d/sogo.conf \
    && ldconfig --verbose
RUN groupadd -f -r sogo \
    && useradd -d /var/lib/sogo -g sogo -c "SOGo daemon" -s /usr/sbin/nologin -r -g sogo sogo \
    && for dir in lib log run spool; do install -m 750 -o sogo -g sogo -d /var/$dir/sogo; done

EXPOSE 80 443 20000
WORKDIR /var/lib/sogo
USER root
ENTRYPOINT ["/usr/local/bin/sogod.sh"]
