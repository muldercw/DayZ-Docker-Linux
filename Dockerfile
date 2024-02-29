FROM debian:bullseye

RUN sed -i -e "s/ main[[:space:]]*\$/ main contrib non-free/" /etc/apt/sources.list
RUN dpkg --add-architecture i386
RUN apt update
# STEAMCMD will be removed from here and separate container used.
RUN echo steam steam/question select "I AGREE" | debconf-set-selections
RUN apt install -y curl cpio libcap2 steamcmd

COPY ./scripts/* /
WORKDIR /server

# Stable:
# STEAM_APP_ID=223350
#
# Experimental:
# STEAM_APP_ID=1042420
ENV STEAM_APP_ID=1042420

#VOLUME ["/server"]
ENTRYPOINT ["/run_server.sh"]
