FROM alpine/git:v2.52.0 AS git
ARG VERSION=v4.13.1

RUN git clone --depth 1 -b ${VERSION} https://github.com/NodeBB/NodeBB.git /nodebb

FROM node:24.18.0-trixie AS build

WORKDIR /app

COPY --from=git /nodebb /app/
RUN cp /app/install/package.json /app

RUN --mount=type=cache,target=/root/.npm \
    npm install --omit=dev

RUN --mount=type=cache,target=/root/.npm \
    npm i \
    nodebb-plugin-meilisearch@^0.7.3

RUN --mount=type=ssh \
    --mount=type=cache,target=/root/.npm \
    GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" \
    npm i \
    git+ssh://git@github.com/bangbang93/nodebb-plugin-sso-oauth.git#master

FROM node:24.18.0-trixie AS runtime

WORKDIR /app/

COPY --from=build /app /app/

VOLUME [ "/app/public/uploads", "/app/build" ]

EXPOSE 4567
CMD ["node", "loader.js", "--no-daemon", "--no-silent"]
