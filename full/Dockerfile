ARG FROM_IMAGE="vbatts/slackware:current"
FROM "${FROM_IMAGE}"
ARG DEV_UID=1000
ARG DEV_GID=1000
ARG DEV_USER=limited
ARG REPO="http://slackware.osuosl.org/slackware64-current/"
RUN echo "${REPO}" > /etc/slackpkg/mirrors
RUN yes y | slackpkg update && \
    slackpkg install-new && \
    slackpkg upgrade-all -default_answer=yes -batch=yes && \
    slackpkg install -default_answer=yes -batch=yes a/* ap/* n/* d/* k/* l/* kde/* y/*

RUN groupadd -g "${DEV_GID}" "${DEV_USER}" ; \
    useradd -m -u "${DEV_UID}" -g "${DEV_GID}" -G wheel "${DEV_USER}" && \
    sed -ri 's/^# (%wheel.*NOPASSWD.*)$/\1/' /etc/sudoers
USER "${DEV_USER}"
ENV HOME /home/"${DEV_USER}"
WORKDIR /home/"${DEV_USER}"

CMD bash -l
