FROM blitznote/debootstrap-amd64:16.10
MAINTAINER W. Mark Kubacki <wmark@hurrikane.de>

RUN apt-get -q update \
 && apt-get -y install \
        kvm qemu-kvm bridge-utils psmisc \
 && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN update-alternatives --install /usr/bin/qemu qemu /usr/bin/qemu-system-x86_64-spice 10

EXPOSE 3389 5900
# 3389  for Windows RDP
# 5900  for QEMU's SPICE
VOLUME /var/cache/media /var/vm

COPY kvm-bootstrap.sh /sbin/kvm-bootstrap.sh

ENTRYPOINT ["/sbin/kvm-bootstrap.sh"]
