#!/usr/bin/env bash

command -v xorriso >/dev/null 2>&1 || { echo >&2 "Please install 'xorriso' first.  Aborting."; exit 1; }
command -v patch >/dev/null 2>&1 || { echo >&2 "Please install 'patch' first.  Aborting."; exit 1; }
command -v wget >/dev/null 2>&1 || { echo >&2 "Please install 'wget' first.  Aborting."; exit 1; }

set -xe

# Basic parameters
#UBUNTU_RELEASE="18.04.3"
DEVICE=nitropad
#UBUNTU_RELEASE="20.04"
UBUNTU_RELEASE="22.04"
UBUNTU_POINT_RELEASE=".1"
RELEASE_ISO_FILENAME="ubuntu-${UBUNTU_RELEASE}${UBUNTU_POINT_RELEASE}-desktop-amd64.iso"
CUSTOM_ISO_FILENAME="ubuntu-${UBUNTU_RELEASE}${UBUNTU_POINT_RELEASE}-${DEVICE}-oem-amd64.iso"

UNPACKED_IMAGE_PATH="./unpacked-iso/"
MBR_IMAGE_FILENAME="${RELEASE_ISO_FILENAME}.mbr"
EFI_IMAGE_FILNAME="${RELEASE_ISO_FILENAME}.efi"

if [ ! -f "${RELEASE_ISO_FILENAME}" ]; then
	wget -q "https://releases.ubuntu.com/${UBUNTU_RELEASE}/${RELEASE_ISO_FILENAME}"
fi

# It's easier to copy the MBR off the original image than to generate a new one
# that would be identical anyway
# see https://askubuntu.com/questions/1403546/ubuntu-22-04-build-iso-both-mbr-and-efi

dd if="${RELEASE_ISO_FILENAME}" bs=1 count=432 of=${MBR_IMAGE_FILENAME}
dd if="${RELEASE_ISO_FILENAME}" bs=512 skip=7129428 count=8496 of=${EFI_IMAGE_FILNAME}

# Unpack ISO, make data writable
xorriso -osirrox on -indev  "${RELEASE_ISO_FILENAME}" -- -extract / "${UNPACKED_IMAGE_PATH}"
chmod -R u+w unpacked-iso/

pushd unpacked-iso
# Patch ISOLINUX and GRUB configs to remove unnecessary choices and, more
# importantly, add kernel command line arguments that force Ubiquity into
# automatic mode
patch -p1 --forward < ../bootconfig-${UBUNTU_RELEASE}.patch
cp ../nitrokey-oem-${UBUNTU_RELEASE}.seed preseed/ubuntu.seed
cp ../post-install.sh ./
popd

# https://askubuntu.com/questions/1403546/ubuntu-22-04-build-iso-both-mbr-and-efi
xorriso -as mkisofs -r \
  -V 'Nitrokey OEM Ubuntu Install' \
  -o $CUSTOM_ISO_FILENAME \
  --grub2-mbr ${MBR_IMAGE_FILENAME} \
  -partition_offset 16 \
  --mbr-force-bootable \
  -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b  ${EFI_IMAGE_FILNAME}\
  -appended_part_as_gpt \
  -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
  -c '/boot.catalog' \
  -b '/boot/grub/i386-pc/eltorito.img' \
    -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
  -eltorito-alt-boot \
  -e '--interval:appended_partition_2:::' \
    -no-emul-boot \
    "${UNPACKED_IMAGE_PATH}"


