#!/usr/bin/env bash

set -xe

# Basic parameters
UBUNTU_RELEASE="18.04.3"
RELEASE_ISO_FILENAME="ubuntu-${UBUNTU_RELEASE}-desktop-amd64.iso"
CUSTOM_ISO_FILENAME="ubuntu-${UBUNTU_RELEASE}-nitrokey-oem-amd64.iso"

UNPACKED_IMAGE_PATH="./unpacked-iso/"
MBR_IMAGE_FILENAME="${RELEASE_ISO_FILENAME}.mbr"

if [ ! -f "${RELEASE_ISO_FILENAME}" ]; then
	wget "http://releases.ubuntu.com/${UBUNTU_RELEASE}/${RELEASE_ISO_FILENAME}"
fi

# It's easier to copy the MBR off the original image than to generate a new one
# that would be identical anyway
dd if="${RELEASE_ISO_FILENAME}" bs=446 count=1 of="${MBR_IMAGE_FILENAME}"

# Unpack ISO, make data writable
xorriso -osirrox on -indev  "${RELEASE_ISO_FILENAME}" -- -extract / "${UNPACKED_IMAGE_PATH}"
chmod -R u+w unpacked-iso/

pushd unpacked-iso
# Patch ISOLINUX and GRUB configs to remove unnecessary choices and, more
# importantly, add kernel command line arguments that force Ubiquity into
# automatic mode
patch -p1 --forward < ../bootconfig.patch
cp ../nitrokey-oem.seed preseed/ubuntu.seed
cp ../post-install.sh ./
popd

# Build the new ISO
xorriso -as mkisofs -r -V "Nitrokey OEM Ubuntu Install" \
	-cache-inodes -J -l \
	-isohybrid-mbr "${MBR_IMAGE_FILENAME}" \
	-c isolinux/boot.cat \
	-b isolinux/isolinux.bin \
		-no-emul-boot -boot-load-size 4 -boot-info-table \
	-eltorito-alt-boot \
	-e boot/grub/efi.img \
		-no-emul-boot -isohybrid-gpt-basdat \
	-o "${CUSTOM_ISO_FILENAME}" \
	"${UNPACKED_IMAGE_PATH}"


