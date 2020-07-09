FROM mcr.microsoft.com/dotnet/core/sdk:3.1-buster

ENV NODE_VERSION 12.18.2
ENV YARN_VERSION 1.22.4
ENV PUPPETEER_VERSION 5.0.0
ENV CHROMEDRIVER_VERSION 83.0.4103.39
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true

# install buildpack, tools, stable chrome with deps
RUN set -ex \
  && apt-get update \
  && apt-get install -yq --no-install-recommends \
  # buildpack deps (https://github.com/docker-library/buildpack-deps/blob/master/buster/Dockerfile)
  autoconf \
  automake \
  bzip2 \
  dpkg-dev \
  file \
  g++ \
  gcc \
  imagemagick \
  libbz2-dev \
  libc6-dev \
  libcurl4-openssl-dev \
  libdb-dev \
  libevent-dev \
  libffi-dev \
  libgdbm-dev \
  libglib2.0-dev \
  libgmp-dev \
  libjpeg-dev \
  libkrb5-dev \
  liblzma-dev \
  libmagickcore-dev \
  libmagickwand-dev \
  libmaxminddb-dev \
  libncurses5-dev \
  libncursesw5-dev \
  libpng-dev \
  libpq-dev \
  libreadline-dev \
  libsqlite3-dev \
  libssl-dev \
  libtool \
  libwebp-dev \
  libxml2-dev \
  libxslt-dev \
  libyaml-dev \
  make \
  patch \
  unzip \
  xz-utils \
  zlib1g-dev \
  # chrome deps (https://github.com/puppeteer/puppeteer/blob/master/docs/troubleshooting.md)
  ca-certificates \
  fonts-liberation \
  gconf-service \
  libappindicator1 \
  libasound2 \
  libatk-bridge2.0-0 \
  libatk1.0-0 \
  libc6 \
  libcairo2 \
  libcups2 \
  libdbus-1-3 \
  libexpat1 \
  libfontconfig1 \
  libgcc1 \
  libgconf-2-4 \
  libgdk-pixbuf2.0-0 \
  libglib2.0-0 \
  libgtk-3-0 \
  libnspr4 \
  libnss3 \
  libpango-1.0-0 \
  libpangocairo-1.0-0 \
  libstdc++6 \
  libx11-6 \
  libx11-xcb1 \
  libxcb1 \
  libxcomposite1 \
  libxcursor1 \
  libxdamage1 \
  libxext6 \
  libxfixes3 \
  libxi6 \
  libxrandr2 \
  libxrender1 \
  libxss1 \
  libxtst6 \
  lsb-release \
  xdg-utils \
  # extra tools
  curl \
  jq \
  parallel \
  wget \
  # install chrome, based on dockerfile from Jessie Frazelle <jess@linux.com>, thank you
  && curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list \
  && apt-get update && apt-get install -yq --no-install-recommends google-chrome-stable \
  # install dumb-init
  && wget https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64.deb \
  && dpkg -i dumb-init_*.deb && rm -f dumb-init_*.deb \
  # https://lists.debian.org/debian-devel-announce/2016/09/msg00000.html
  $( \
  # if we use just "apt-cache show" here, it returns zero because "Can't select versions from package 'libmysqlclient-dev' as it is purely virtual", hence the pipe to grep
  if apt-cache show 'default-libmysqlclient-dev' 2>/dev/null | grep -q '^Version:'; then \
  echo 'default-libmysqlclient-dev'; \
  else \
  echo 'libmysqlclient-dev'; \
  fi \
  ) \
  # cleanup apt
  && apt-get clean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

# https://github.com/nodejs/docker-node/blob/master/12/buster/Dockerfile
# FROM node:12.16.1
RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

# install nodejs
RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
  && case "${dpkgArch##*-}" in \
  amd64) ARCH='x64';; \
  ppc64el) ARCH='ppc64le';; \
  s390x) ARCH='s390x';; \
  arm64) ARCH='arm64';; \
  armhf) ARCH='armv7l';; \
  i386) ARCH='x86';; \
  *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  # gpg keys listed at https://github.com/nodejs/node#release-keys
  && set -ex \
  && for key in \
  94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
  FD3A5288F042B6850C66B31F09FE44734EB7990E \
  71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
  DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
  C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
  B9AE9905FFD7803F25714661B63B535A4C206CA9 \
  77984A986EBC2AA786BC0F66B01FBB92821C587A \
  8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
  4ED778F539E3634C779C87C6D7062848A1AB005C \
  A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
  B9E2F5981AA6E0CD28160D9FF13993A75599653C \
  ; do \
  gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
  gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
  gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
  # smoke tests
  && node --version \
  && npm --version

# install yarn
RUN set -ex \
  && for key in \
  6A010C5166006599AA17F08146C2130DFD2497F5 \
  ; do \
  gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
  gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
  gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
  && gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  && mkdir -p /opt \
  && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/ \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarn /usr/local/bin/yarn \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarnpkg /usr/local/bin/yarnpkg \
  && rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  # smoke test
  && yarn --version

# install chromedriver
RUN set -x \
  && curl -sSL "https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip" -o /tmp/chromedriver.zip \
  && unzip -o /tmp/chromedriver -d /usr/local/bin/ \
  && chmod +x /usr/local/bin/chromedriver \
  && rm -rf /tmp/*.deb \
  && rm -rf /tmp/*.zip

# install puppeteer
RUN yarn global add puppeteer@$PUPPETEER_VERSION && yarn cache clean

ENV NODE_PATH="/usr/local/share/.config/yarn/global/node_modules:${NODE_PATH}"

# add chrome user
RUN groupadd -r chrome \
  && useradd -r -g chrome -G audio,video chrome \
  && mkdir -p /home/chrome/Downloads \
  && chown -R chrome:chrome /home/chrome \
  && chown -R chrome:chrome /usr/local/share/.config/yarn/global/node_modules \
  && mkdir -p /opt/buildagent \
  && chmod -R +w /opt \
  && chown -R chrome:chrome /opt/buildagent

# print missing chrome deps if any
RUN echo 'missing chrome deps' && (ldd /opt/google/chrome/chrome | grep not) || true

# run everything after as non-privileged user
USER chrome

ENTRYPOINT ["dumb-init", "--"]
