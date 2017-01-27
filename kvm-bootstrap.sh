#!/bin/bash

set -eo pipefail
if [[ ! -z ${debug+x} ]]; then
  set -x
fi

if [[ ! -c "/dev/kvm" ]]; then
  rm /dev/kvm || true
  set +e
  read -r NODNUM _ < <(grep '\<kvm\>' /proc/misc)
  mknod /dev/kvm c 10 "${NODNUM}"
  set -e
else
  if ! dd if=/dev/kvm count=0 2>/dev/null; then
    >&2 printf "Cannot open /dev/kvm - please run this in a privileged context.\n"
    # see: /usr/include/sysexits.h: EX_OSFILE
    exit 72
  fi
fi

if [[ ! -z "${BRIDGE_IF+x}" ]]; then
  printf "allow ${BRIDGE_IF}" >/etc/qemu/bridge.conf

  # Make sure we have the tun device node
  if [[ ! -c "/dev/net/tun" ]]; then
    rm /dev/net/tun || true
    mkdir -p /dev/net
    set +e
    read -r NODNUM _ < <(grep '\<tun\>' /proc/misc)
    mknod /dev/net/tun c 10 "${NODNUM}"
    set -e
  fi
fi

# shortcuts such as:
#   windows <spice address> <spice port> <spice password> <MAC> <nic-device> <name> <memory in MB> <boot ISO>
# example:
#   windows ${COREOS_PUBLIC_IPV4} 5900 geheim 52:54:00:xx:xx:xx macvtap0 "windows-1" $((16 * 8 * 1024)) Windows-10-threshold-2-take-1.iso

if (( $# >= 8 )) && [[ "$1" == "windows" ]]; then
  curl --silent --show-error --fail --location --remote-time \
    --{time-cond,output}/var/cache/media/virtio-win.iso \
    https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso \
  || true

  if [[ ! -e /var/vm/disks/"$7".img ]]; then
    mkdir -p /var/vm/disks
    chmod 0700 /var/vm/disks
    qemu-img create -f qcow2 /var/vm/disks/"$7".img 80G
  fi

  read MAJOR MINOR < <(cat /sys/devices/virtual/net/$6/tap*/dev | tr ':' ' ')
  mknod /dev/tap-vm c ${MAJOR} ${MINOR}

#   -device virtio-balloon,id=balloon0,bus=pci.0,addr=0x7 \ Windows 10 won't start with this

  : ${ncores:="4"}
  if (( $(nproc) > 16 )); then
    # MCC or HCC cpu(s)
    if (( $(nproc) > 20)); then
      let ncores="$[ $(nproc --ignore 4)/2 ]"
    else
      let ncores="$(nproc --ignore 2)"
    fi
  fi

  drives=()
  drives+=("-drive" "file=/var/vm/disks/$7.img,if=virtio,index=0,media=disk")
  drives+=("-drive" "file=/var/cache/media/virtio-win.iso,index=3,media=cdrom,readonly")
  if (( $# >= 9 )); then
    if [[ -s "/var/cache/media/$9" ]]; then
      drives+=("-drive" "file=/var/cache/media/$9,index=2,media=cdrom,readonly")
      drives+=("-boot" "once=d")
    else
      >&2 printf "Ignored, because it is no file: %s\n" "$9"
    fi
  fi
  spice=()
  spice+=("-vga" "none" "-device qxl-vga,vgamem_mb=32")
  spice+=("-spice" "addr=$2,port=$3,password=$4")
  spice+=("-chardev" "spicevmc,id=vdagent,name=vdagent")
  spice+=("-device" "virtserialport,chardev=vdagent,name=com.redhat.spice.0")

  exec /usr/bin/qemu -enable-kvm -nographic -rtc base=utc \
    -monitor unix:/run/kvm/"$7".monitor,server,nowait \
    -cpu host -m $8 -smp ${ncores},sockets=1 -k de -usbdevice tablet \
    -device virtio-serial \
    ${spice[*]} \
    -net nic,model=virtio,macaddr=$5 -net tap,fd=3 3<>/dev/tap-vm \
    ${drives[*]} \
    -name "$7"
else
  exec /usr/bin/qemu -enable-kvm "$@"
fi
