#!/usr/bin/env bash

command -v xorriso >/dev/null 2>&1 || { echo >&2 "Please install 'xorriso' first.  Aborting."; exit 1; }
command -v patch >/dev/null 2>&1 || { echo >&2 "Please install 'patch' first.  Aborting."; exit 1; }
command -v wget >/dev/null 2>&1 || { echo >&2 "Please install 'wget' first.  Aborting."; exit 1; }

set -xe

# Basic parameters
DEVICE=nitropad_nitropc
UBUNTU_RELEASE="24.04"
UBUNTU_POINT_RELEASE=""
RELEASE_ISO_FILENAME="ubuntu-${UBUNTU_RELEASE}${UBUNTU_POINT_RELEASE}-desktop-amd64.iso"
CUSTOM_ISO_FILENAME="ubuntu-${UBUNTU_RELEASE}${UBUNTU_POINT_RELEASE}-${DEVICE}-oem-$1-amd64.iso"
DOWNLOAD_URL="https://releases.ubuntu.com/${UBUNTU_RELEASE}/${RELEASE_ISO_FILENAME}"
GENISO_BOOTIMG="boot/grub/i386-pc/eltorito.img"
GENISO_BOOTCATALOG="/boot.catalog"
GENISO_START_SECTOR="$(LANG=C fdisk -l ${RELEASE_ISO_FILENAME} |grep iso2 | cut -d' ' -f2)"
GENISO_END_SECTOR="$(LANG=C fdisk -l ${RELEASE_ISO_FILENAME} |grep iso2 | cut -d' ' -f3)"

UNPACKED_IMAGE_PATH="./unpacked-iso/"

if [ ! -f "${RELEASE_ISO_FILENAME}" ]; then
        wget -q ${DOWNLOAD_URL} -O ${RELEASE_ISO_FILENAME}
fi

xorriso -osirrox on -indev  "${RELEASE_ISO_FILENAME}" -- -extract / "${UNPACKED_IMAGE_PATH}"
chmod -R u+w ${UNPACKED_IMAGE_PATH}

sed -i 's/Ubuntu/Nitrokey OEM/g' ${UNPACKED_IMAGE_PATH}boot/grub/grub.cfg

cp autoinstall.yaml ${UNPACKED_IMAGE_PATH}

if [ $1 == "en" ]; then
	sed -i "s/de_DE/en_US/g" ${UNPACKED_IMAGE_PATH}autoinstall.yaml
	sed -i "s/layout: de/layout: us/g" ${UNPACKED_IMAGE_PATH}autoinstall.yaml
fi


# https://github.com/YasuhiroABE/ub-autoinstall-iso/blob/main/Makefile
LANG=C xorriso -as mkisofs  \
	-V 'Nitrokey OEM Ubuntu Install' \
	-output "$CUSTOM_ISO_FILENAME"  \
	-eltorito-boot "${GENISO_BOOTIMG}" \
	-eltorito-catalog "${GENISO_BOOTCATALOG}" -no-emul-boot \
	-boot-load-size 4 -boot-info-table -eltorito-alt-boot \
	-no-emul-boot -isohybrid-gpt-basdat \
	-append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b --interval:local_fs:${GENISO_START_SECTOR}d-${GENISO_END_SECTOR}d::"${RELEASE_ISO_FILENAME}" \
	-e '--interval:appended_partition_2_start_1782357s_size_8496d:all::' \
	--grub2-mbr --interval:local_fs:0s-15s:zero_mbrpt,zero_gpt:"${RELEASE_ISO_FILENAME}" \
	"${UNPACKED_IMAGE_PATH}"
