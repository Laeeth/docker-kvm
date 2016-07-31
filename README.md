QEMU/KVM using macvtap, in Docker
=================================

Works with CoreOS and Ubuntu.

- Request a »virtual MAC« for the guest, if you run this in a datacenter.  
  If this is in your LAN, then just pick an unique MAC address.
- Prepare a Windows (or Linux, or BSD) ISO.
- Get the **Remote Viewer** here: http://www.spice-space.org/download.html

## Example: Windows 10

Prepare the host:

```bash
mkdir -p /var/vm /run/kvm
chattr -R +C /var/vm
chmod 0700 /run/kvm

mkdir /var/cache/media
cd /var/cache/media
# download, for example, a Windows10.iso

if grep -q CoreOS /etc/os-release; then
  mkdir -p /opt/bin

  curl -fLR -o /opt/bin/plzip \
    https://s.blitznote.com/debs/ubuntu/amd64/plzip
  ln -s plzip /opt/bin/lzip
  chmod a+x /opt/bin/plzip

  curl -fLsS -o - \
    https://s.blitznote.com/os/coreos/netcat.tar.lz \
  | tar --use-compress-program=/opt/bin/lzip -xv -C /
  ldconfig
else
  apt-get -y install netcat-openbsd
fi
```

Install the *systemd unit file* which takes care of starting, resetting, and stopping the KVM:

```bash
cp -a systemd-examples/windows-macvtap.service /etc/systemd/system/kvm-windows-1.service
systemctl daemon-reload

systemctl edit --full kvm-windows-1.service
# More than a single VM? change port 5900 to something else.
# Customize all "VM_*" values.
# 'ext0' on my host might be 'eth0' on yours - change that in the file accordingly.
# Replace ${COREOS_PUBLIC_IPV4} by 127.0.0.1 or your host's IP address for the remote viewer endpoint.
```

And finally, start the KVM and point the **Remote Viewer** to `spice://<host ip>:5900`

```bash
systemctl start kvm-windows-1.service
systemctl enable kvm-windows-1.service
```

You will need to install Windows (or Linux, or BSD) if the virtual HDD is empty.
The *virtio* drivers for Windows will be available in the seconds virtual DVD drive.
Have the Windows installer load **NetKVM** first, even though it is no storage driver;
then **viostor**. With *Windows 10* point to subfolder `2k12R2/amd64`.

Once the system is ready you can install all remaining drivers by right-clicking on the corresponding INF file.
Don't forget the *guest agent*!
