FROM buildpack-deps:jessie
FROM node:7.2.0
RUN npm install -g elm@0.18.0
RUN npm install -g elm-test@0.18.0
RUN npm install --global yarn
ENV OTP_VERSION="19.3"
RUN set -xe \
        && OTP_DOWNLOAD_URL="https://github.com/erlang/otp/archive/OTP-${OTP_VERSION}.tar.gz" \
        && OTP_DOWNLOAD_SHA256="fc82c5377ad9e84a37f67f2b2b50b27fe4e689440ae9e5d0f5dcfb440a9487ac" \
        && runtimeDeps='libodbc1 \
                        libsctp1 \
                        libwxgtk3.0-0' \
        && buildDeps='unixodbc-dev \
                        libsctp-dev \
                        libwxgtk3.0-dev' \
        && apt-get update \
        && apt-get install -y --no-install-recommends $runtimeDeps \
        && apt-get install -y --no-install-recommends $buildDeps \
        && curl -fSL -o otp-src.tar.gz "$OTP_DOWNLOAD_URL" \
        && echo "$OTP_DOWNLOAD_SHA256 otp-src.tar.gz" | sha256sum -c - \
        && mkdir -p /usr/src/otp-src \
        && tar -xzf otp-src.tar.gz -C /usr/src/otp-src --strip-components=1 \
        && rm otp-src.tar.gz \
        && cd /usr/src/otp-src \
        && ./otp_build autoconf \
        && ./configure \
                --enable-sctp \
                --enable-dirty-schedulers \
        && make -j$(nproc) \
        && make install \
        && find /usr/local -name examples | xargs rm -rf \
        && apt-get purge -y --auto-remove $buildDeps \
        && rm -rf /usr/src/otp-src /var/lib/apt/lists/*
#Here we should probably start some erlang nodes etc etc
RUN git clone https://github.com/erlanglab/erlangpl && cd erlangpl && make rebar && make release
CMD epmd -daemon && epmd -names && erl -name testnode@127.0.0.1 -setcookie test -detached -noinput -noshell && cd erlangpl && ./erlangpl -n testnode@127.0.0.1 -c test
EXPOSE 37575
