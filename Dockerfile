FROM alpine
RUN apk add git curl bash
WORKDIR /
COPY updater.sh updater.sh
RUN chmod +x updater.sh
USER 65534
ENTRYPOINT ./updater.sh