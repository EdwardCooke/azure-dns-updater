FROM debian
#RUN apk add git curl bash
RUN apt update && \
    apt install -y git curl
WORKDIR /
COPY updater.sh updater.sh
RUN chmod +x updater.sh
USER 65534
ENTRYPOINT ./updater.sh