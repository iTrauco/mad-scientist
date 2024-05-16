#!/usr/bin/env bash

#!/bin/bash

# Define variables for USB creation
ISO_PATH="$HOME/isos/mad-scientist-20.04.iso"  # Path to the ISO file created above
USB_DEVICE="/dev/sda"                          # USB device (base device, not partition)
PERSISTENCE_LABEL="casper-rw"                  # Label for the persistence partition

# Ensure the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root"
    exit 1
fi

# Confirm the USB device
echo "Warning: This will erase all data on $USB_DEVICE"
read -p "Are you sure you want to continue? (y/n) " response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 1
fi

# Unmount all partitions on the USB device
umount ${USB_DEVICE}* || true

# Wipe the USB device
echo "Wiping the USB device..."
dd if=/dev/zero of=$USB_DEVICE bs=4M status=progress oflag=sync
if [ $? -ne 0 ]; then
    echo "Failed to wipe the USB device."
    exit 1
fi

# Write the ISO to the USB device using dd
echo "Writing ISO to USB device..."
dd if="$ISO_PATH" of="$USB_DEVICE" bs=4M status=progress oflag=sync
if [ $? -ne 0 ]; then
    echo "Failed to write ISO to USB device."
    exit 1
fi

# Create the persistence partition
echo "Creating persistence partition..."
parted --script $USB_DEVICE mkpart primary ext4 $(($(blockdev --getsize64 $USB_DEVICE) / 1024 / 1024))MiB 100%
if [ $? -ne 0 ]; then
    echo "Failed to create persistence partition."
    exit 1
fi

# Wait for the system to recognize the new partition
sleep 1

# Format the persistence partition
mkfs.ext4 -L $PERSISTENCE_LABEL ${USB_DEVICE}2
if [ $? -ne 0 ]; then
    echo "Failed to format persistence partition."
    exit 1
fi

# Create and mount the persistence directory
PERSISTENCE_DIR="/mnt/$PERSISTENCE_LABEL"
if [ ! -d "$PERSISTENCE_DIR" ]; then
    mkdir -p "$PERSISTENCE_DIR"
    if [ $? -ne 0 ]; then
        echo "Failed to create persistence directory."
        exit 1
    fi
fi

mount ${USB_DEVICE}2 $PERSISTENCE_DIR
if [ $? -ne 0 ]; then
    echo "Failed to mount persistence partition."
    exit 1
fi

# Configure persistence
echo "/ union" > $PERSISTENCE_DIR/persistence.conf
if [ $? -ne 0 ]; then
    echo "Failed to configure persistence."
    exit 1
fi

umount $PERSISTENCE_DIR
if [ $? -ne 0 ]; then
    echo "Failed to unmount persistence partition."
    exit 1
fi

echo "Bootable USB with persistence created successfully."

# Eject the USB drive
eject $USB_DEVICE
if [ $? -ne 0 ]; then
    echo "Failed to eject USB device."
    exit 1
fi

exit 0

