# Ubuntu LTS unattended OEM installer with LUKS+LVM

This script creates an installer image for Ubuntu LTS (currently 18.04) that
 - works unattended (plug in, power on, leave alone for 10 minutes)
 - performs an OEM install - on the subsequent boot the user will be presented with the installer screen to set up their language, timezone, login info, etc.
 - sets up LVM on LUKS with initial password

# WARNING WARNING WARNING
DO NOT BOOT THIS IMAGE ON ANY COMPUER THAT CONTAINS ANY USEFUL DATA
This installer is COMPLETELY UNATTENDED, it doesn't need a keypress to start, doesn't ask any questions, doesn't wait for any confirmation and IT WILL ERASE THE COMPUTERS'S STORAGE COMPLETELY AND UNCONDITIONALLY, including existing LVMs.

You have been warned. Label the disc or pendrive appropriately to avoid mistakes.

# Initial LUKS password

Yes, the initial password for LUKS is hardcoded in the preseed file. Even if it weren't literally hardcoded (which is easy enough to fix, and probably will be; not a big deal anyway), all installations performed with a single image will share the initial password. However, thanks to how LUKS uses passwords, the actual encryption master key will be different on each install. As long as the password is changed by the end user, their installation will not share any key material with other instances.

It is, of course, possible for a vendor using this installer to covertly copy the LUKS master key off the installed system between installation and first boot, to retain access to data (unless the user runs cryptsetup-reencrypt). It's also possible for the vendor to just backdoor the initrd (which contains the LUKS password prompt), or the OS itself, or the bootloader, or the firmware, or any other part of the computer. The usual caveats for using any pre-installed software/firmware/etc. still apply.

# TODO

 - parametrized preseed file, mainly to provide the initial LUKS password at build time
 - additional Ubiquity installer form or initrd prompt asking the user to provide a new LUKS password on first boot
 - use cryptsetup-reencrypt to replace the LUKS master key on first boot (needs to be done in initrd)

# Usage

Run make-image.sh to build an OEM image (or [download](https://www.nitrokey.com/files/ci/nitropc/ubuntu-oem/) the image). Use a DVD or pendrive like with a regular Ubuntu installer. No other actions are needed, the script will download the official ISO itself.

