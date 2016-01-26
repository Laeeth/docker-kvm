FROM		blitznote/debootstrap-amd64:16.04
MAINTAINER	W. Mark Kubacki <wmark@hurrikane.de>

RUN printf "deb [ trusted=yes arch=amd64 ] https://s.blitznote.com/debs/ubuntu/amd64/ all/" > /etc/apt/sources.list.d/blitznote.list \
 && printf 'Package: *\nPin: origin "s.blitznote.com"\nPin-Priority: 510\n' > /etc/apt/preferences.d/prefer-blitznote

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
