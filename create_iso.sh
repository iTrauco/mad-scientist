#!/usr/bin/env bash
#!/bin/bash

# Define variables for ISO creation
IMAGE_NAME="mad-scientist-20.04.iso"
OUTPUT_DIR="$HOME/isos"
WORK_DIR="/tmp/debian-iso"
CHROOT_DIR="$WORK_DIR/chroot"
ISO_DIR="$WORK_DIR/iso"
MOUNT_DIR="$WORK_DIR/mount"

# Ensure the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root"
    exit 1
fi

# Install required packages
apt-get update
apt-get install -y debootstrap squashfs-tools genisoimage grub-pc-bin grub-efi-amd64-bin xorriso

# Create working directories
mkdir -p $CHROOT_DIR $ISO_DIR $MOUNT_DIR $OUTPUT_DIR

# Create a minimal Debian system using debootstrap
debootstrap --arch=amd64 buster $CHROOT_DIR http://deb.debian.org/debian/

# Mount necessary filesystems
mount --bind /dev $CHROOT_DIR/dev
mount --bind /dev/pts $CHROOT_DIR/dev/pts
mount --bind /proc $CHROOT_DIR/proc
mount --bind /sys $CHROOT_DIR/sys

# Copy DNS info
cp /etc/resolv.conf $CHROOT_DIR/etc/

# Chroot and configure the system
chroot $CHROOT_DIR /bin/bash <<EOF
apt-get update
apt-get install -y linux-image-amd64 casper lupin-casper grub-pc-bin grub-efi-amd64-bin
EOF

# Unmount filesystems
umount -lf $CHROOT_DIR/dev/pts
umount -lf $CHROOT_DIR/dev
umount -lf $CHROOT_DIR/proc
umount -lf $CHROOT_DIR/sys

# Create the squashfs file
mksquashfs $CHROOT_DIR $ISO_DIR/casper/filesystem.squashfs -e boot

# Create the ISO structure
mkdir -p $ISO_DIR/{casper,isolinux,install}
cp $CHROOT_DIR/boot/vmlinuz-* $ISO_DIR/casper/vmlinuz
cp $CHROOT_DIR/boot/initrd.img-* $ISO_DIR/casper/initrd

# Create the isolinux configuration
cat <<EOF > $ISO_DIR/isolinux/isolinux.cfg
UI menu.c32
PROMPT 0
MENU TITLE Custom Debian Boot Menu
TIMEOUT 50

LABEL linux
  menu label ^Install Custom Debian
  kernel /casper/vmlinuz
  append initrd=/casper/initrd boot=casper quiet splash ---
EOF

# Copy isolinux binary
cp /usr/lib/ISOLINUX/isolinux.bin $ISO_DIR/isolinux/
cp /usr/lib/syslinux/modules/bios/* $ISO_DIR/isolinux/

# Create the bootable ISO using xorriso and grub-mkrescue
grub-mkrescue -o $OUTPUT_DIR/$IMAGE_NAME $ISO_DIR

# Clean up
umount -lf $MOUNT_DIR
rm -rf $CHROOT_DIR

echo "ISO created at $OUTPUT_DIR/$IMAGE_NAME"

