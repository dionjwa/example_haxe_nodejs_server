FROM debian:jessie
MAINTAINER Dion Amago Whitehead

ENV DEBIAN_FRONTEND noninteractive
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

################################################################################
# Haxe
################################################################################

# Neko environment variables
ENV NEKOVERSION=2.0.0 NEKOPATH=/opt/neko
ENV HAXEVERSION=3.3.0-rc.1 HAXEPATH=/opt/haxe HAXELIB_PATH=/opt/haxelib

# Dependencies
RUN apt-get update \
    && apt-get install -y \
      wget \
      libgc-dev \
      git && \
    mkdir -p $NEKOPATH && \
    wget -O - http://nekovm.org/_media/neko-$NEKOVERSION-linux64.tar.gz \
    | tar xzf - --strip=1 -C $NEKOPATH && \
    mkdir -p $HAXEPATH && \
    wget -O - http://haxe.org/website-content/downloads/$HAXEVERSION/downloads/haxe-$HAXEVERSION-linux64.tar.gz \
      | tar xzf - --strip=1 -C $HAXEPATH && \
    mkdir -p $HAXELIB_PATH && echo $HAXELIB_PATH > /root/.haxelib && cp /root/.haxelib /etc/ && \
	# apt-get -y remove wget && \
	apt-get -y autoremove && \
	apt-get -y clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

################################################################################

ENV LD_LIBRARY_PATH $NEKOPATH
ENV PATH $NEKOPATH:$PATH
ENV HAXE_STD_PATH $HAXEPATH/std/
ENV PATH $HAXEPATH:$PATH

# workaround for https://github.com/HaxeFoundation/haxe/issues/3912
ENV HAXE_STD_PATH $HAXE_STD_PATH:.:/

################################################################################
# Node.js
################################################################################
RUN apt-get update \
  && apt-get install -y build-essential curl tar && \
  apt-get -y autoremove && \
  apt-get -y clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV NODE_VERSION "v6.7.0"

# Download
RUN curl -LO http://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-x64.tar.gz && \
    tar xzf node-$NODE_VERSION-linux-x64.tar.gz && \
    cp -R ./node-$NODE_VERSION-linux-x64/bin/* /usr/local/bin && \
    cp -R ./node-$NODE_VERSION-linux-x64/lib/* /usr/local/lib && \
    cp -R ./node-$NODE_VERSION-linux-x64/include/* /usr/local/include && \
    cp -R ./node-$NODE_VERSION-linux-x64/share/* /usr/local/share && \
    rm -rf ./node-$NODE_VERSION-linux-x64.tar.gz && \
    rm -rf ./node-$NODE_VERSION-linux-x64

################################################################################
# App setup
################################################################################

CMD ["/bin/bash"]

ENV APP /app
RUN mkdir -p $APP
WORKDIR $APP

################################################################################
# Npm packages
################################################################################

ADD ./package.json $APP/package.json
RUN npm install

################################################################################
# Haxe packages
################################################################################
RUN haxelib newrepo

#Only install haxe packages if the package.json changes
ADD ./build.hxml $APP/build.hxml
RUN haxelib install --always $APP/build.hxml

################################################################################
# Actual app code
################################################################################
ADD ./src $APP

CMD node build/server.js
