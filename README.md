QEMU/KVM using macvtap, in Docker
=================================

[![](https://badge.imagelayers.io/wmark/docker-kvm:latest.svg)](https://imagelayers.io/?images=wmark/docker-kvm:latest 'image stats by imagelayers.io')

Works on CoreOS and BaseOS.

- Request a »virtual MA« for the desiredIP address, if you run this in a datacenter.
  You don't need to do this in your LAN. In that case, just pick a unique MAC address.
- Link a macvtap device to your external NIC. For example ```link ext0 name ${VM_TAP}```.
- … pass its name to the Docker container, which in turn re-creates the corresponding ```/dev/tap*``` device.

```bash
ip link add link ext0 name macvtap0 type macvtap
ip link set macvtap0 address 52:54:00:12:34:56 up
ip link show macvtap0

# That's what happens within the Docker container:
#   read MAJOR MINOR < <(cat /sys/devices/virtual/net/macvtap0/tap*/dev | tr ':' ' ')
#   mknod /dev/tap-vm c ${MAJOR} ${MINOR}

/bin/docker run -t --rm --privileged \
  --net host \
  -v /var/cache/media:/var/cache/media \
  -v /var/vm:/var/vm \
  -v /run/kvm:/run/kvm \
  wmark/docker-kvm \
    -cpu host -m $((16 * 8 * 128)) -smp cpus=1,cores=2,threads=4 -usbdevice tablet \
    -device qxl-vga,vgamem_mb=32 \
    -device virtio-serial \
    -chardev spicevmc,id=vdagent,name=vdagent \
    -device virtserialport,chardev=vdagent,name=com.redhat.spice.0 \
    -net nic,model=virtio,macaddr=52:54:00:12:34:56 -net tap,fd=3 3<>/dev/tap-vm \
    -drive file=/var/vm/disks/windows-1.img,if=virtio,index=0,media=disk \
    -drive file=/var/cache/media/Windows-10-threshold-2-take-1.iso,index=2,media=cdrom,readonly \
    -drive file=/var/cache/media/virtio-win.iso,index=3,media=cdrom,readonly \
    -boot once=d \
    -name "windows-1"

# Get the »remote viewer« from: https://virt-manager.org/download/

ip link set dev macvtap0 down
ip link del macvtap0
```

See the **systemd-examples** folder for how to automate this.
