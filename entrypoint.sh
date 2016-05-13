#!/bin/bash
echo "Creating developer user..."

export HOME=/home/developer
export uid=${UID:-1000} gid=${GID:-1000} && \
    mkdir -p /home/developer && \
    echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} -R /home/developer

#su -u developer -c  "byobu -p2 -X \"$@\""
#su developer -c  "$@"
sudo -u developer -s