FROM debian:stretch-slim

ENV TZ=Europe/Moscow
ENV NGINX_VERSION=1.16.0
ENV OPENSSL_VERSION=1.0.2n
LABEL nginx=1.14.0 openssl=1.0.2n

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    #
    && DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get --no-install-recommends -qq -y install wget curl apt-transport-https lsb-release ca-certificates zlib1g-dev cmake build-essential vim libboost-all-dev git zip \
    && mkdir /soft/ \
    #
    && cd /soft/ \
    && wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.40.tar.gz \
    && tar -zxf pcre-8.40.tar.gz \
    && cd pcre-8.40 \
    && ./configure \
    && make \
    && make install \
    #
    && cd /soft/ \
    && wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz \
    && tar -zxf openssl-${OPENSSL_VERSION}.tar.gz \
    && cd openssl-${OPENSSL_VERSION} \
    && ./config --prefix=/usr \
    && make \
    && make install \
    #
    && cd /soft/ \
    && git clone https://github.com/vozlt/nginx-module-vts.git nginx-module-vts \
    #
    && cd /soft/ \
    && git clone git://github.com/bpaquet/ngx_http_enhanced_memcached_module.git \
    #
    #
    && cd /soft/ \
    && wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.40.tar.gz \
    && tar -zxf pcre-8.40.tar.gz \
    && cd pcre-8.40 \
    && ./configure \
    && make \
    && make install \
    #
    && cd /soft/ \
    && git clone --recursive https://github.com/google/ngx_brotli.git ngx_brotli \
    && cd ngx_brotli \
    && git submodule update --init \
    #
    && cd /soft/ \
    && git clone --recursive https://github.com/google/open-vcdiff open-vcdiff \
    && cd open-vcdiff \
    && cmake . \
    && make install \
    #
    && mkdir -p /etc/nginx/ \
    && cd /soft/ \
    && useradd --no-create-home nginx \
    && wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar -zxf nginx-${NGINX_VERSION}.tar.gz \
    && cd nginx-${NGINX_VERSION} \
    && ./configure \
            --sbin-path=/usr/sbin/nginx \
            --conf-path=/etc/nginx/nginx.conf \
            --pid-path=/var/run/nginx.pid \
            --error-log-path=/dev/stdout \
            --http-log-path=/dev/stdout  \
            --with-http_ssl_module \
            --with-openssl=/soft/openssl-${OPENSSL_VERSION}/ \
            --with-http_gzip_static_module \
            --with-http_addition_module \
            --with-http_realip_module \
            --with-http_v2_module \
            --with-threads \
            --with-http_slice_module \
            --with-file-aio \
            --with-stream \
            --with-stream_ssl_module \
            --add-module=../ngx_brotli/ \
            --add-module=../nginx-module-vts/ \
            --add-module=../ngx_http_enhanced_memcached_module/ \
    && make \
    && make install \
    && export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH} \
    #
    && apt-get -y remove wget curl apt-transport-https lsb-release ca-certificates zlib1g-dev cmake build-essential vim libboost-all-dev git zip \
    && apt-get -y autoremove \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /soft/

COPY conf/*.conf /etc/nginx/

CMD ["nginx", "-g", "daemon off;"]
