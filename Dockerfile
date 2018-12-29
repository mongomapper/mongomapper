ARG RUBY_VERSION

FROM ruby:$RUBY_VERSION-alpine

ENV BUNDLE_JOBS=4 \
  BUNDLE_PATH=/vendor/bundle/$RUBY_VERSION

RUN apk update && apk add --no-cache build-base tzdata less socat git ca-certificates wget && update-ca-certificates

ENV ENTRYKIT_VERSION 0.4.0
RUN wget https://github.com/progrium/entrykit/releases/download/v${ENTRYKIT_VERSION}/entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz \
  && tar -xvzf entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz \
  && rm entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz \
  && mv entrykit /bin/entrykit \
  && chmod +x /bin/entrykit \
  && entrykit --symlink

COPY docker /docker

RUN gem update bundler

RUN adduser -u 1000 -D app && \
  mkdir -p /app /vendor && \
  chown -R app:app /app /vendor $GEM_HOME $BUNDLE_BIN

USER app

ENTRYPOINT [ "prehook", "/docker/prehook", "--" ]
