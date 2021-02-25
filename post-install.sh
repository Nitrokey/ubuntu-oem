#!/usr/bin/env sh

# Prepare for shipping immediately
oem-config-prepare --quiet

# Remove Amazon ads
apt-get -y remove ubuntu-web-launchers

# Install Nitrokey App
add-apt-repository -y ppa:nitrokey/nitrokey
apt-get -y install nitrokey-app

# Install dkms rtl8821ce driver
apt-get -y install rtl8821ce-dkms

# Add a new dconf database and use it to append Nitrokey App to favorite apps
echo "user-db:user" > /etc/dconf/profile/user
echo "system-db:local" >> /etc/dconf/profile/user

mkdir -p /etc/dconf/db/local.d/ 

echo "[org/gnome/shell]" > /etc/dconf/db/local.d/01-favorites
grep favorite-apps /usr/share/glib-2.0/schemas/10_ubuntu-settings.gschema.override | sed "s/ ]$/, 'nitrokey-app.desktop' ]/" >> /etc/dconf/db/local.d/01-favorites 

dconf update

# Cleanup
rm /root/post-install.sh
