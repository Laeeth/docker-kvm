FROM		ubuntu-debootstrap:15.10
MAINTAINER	W. Mark Kubacki <wmark@hurrikane.de>

RUN printf "\tif [[ \${EUID} == 0 ]] ; then\n\t\tPS1='\\[\\\\033[01;31m\\]\\h\\[\\\\033[01;96m\\] \\W \\$\\[\\\\033[00m\\] '\n\telse\n\t\tPS1='\\[\\\\033[01;32m\\]\\u@\\h\\[\\\\033[01;96m\\] \\w \\$\\[\\\\033[00m\\] '\n\tfi\n" >> /etc/bash.bashrc \
 && sed -i -e "/color_prompt.*then/,/fi/{N;d}" /root/.bashrc \
 && printf 'alias dir="ls -hlAS --time-style=long-iso --color"\n' >> /etc/bash.bashrc \
 && update-locale LANG=C.UTF-8

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get -qq update \
 && apt-get -y -qq install apt-transport-https \
 && printf "deb https://s.blitznote.com/debs/ubuntu/amd64/ all/" > /etc/apt/sources.list.d/blitznote.list \
 && printf 'Package: *\nPin: origin "s.blitznote.com"\nPin-Priority: 510\n' > /etc/apt/preferences.d/prefer-blitznote \
 && printf "deb http://de.archive.ubuntu.com/ubuntu/ xenial main restricted universe multiverse\ndeb-src http://de.archive.ubuntu.com/ubuntu/ xenial main restricted universe multiverse" > /etc/apt/sources.list.d/ubuntu-xenial.list \
 && apt-get -qq update \
 && apt-get install -y --force-yes curl ca-certificates signify-linux \
 && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get -qq update \
 && apt-get -y install \
        kvm qemu-kvm bridge-utils psmisc \
        unzip unrar-free lbzip2 pigz plzip p7zip-full \
 && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN update-alternatives --install /usr/bin/qemu qemu /usr/bin/qemu-system-x86_64-spice 10

EXPOSE 3389 5900
# 3389  for Windows RDP
# 5900  for QEMU's SPICE

VOLUME /var/cache/media /var/vm

ADD kvm-bootstrap.sh /sbin/kvm-bootstrap.sh

ENTRYPOINT ["/sbin/kvm-bootstrap.sh"]
