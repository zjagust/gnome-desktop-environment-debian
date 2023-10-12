#!/usr/bin/env bash

#######################################################################################################
#
# Zack's - GNOME Desktop Environment autoinstall script
# Version: 1.0
#
# This script will install all packages required for GNOME Desktop Environment on Debian Linux.
#
# © 2023 Zack's. All rights reserved.
#
#######################################################################################################

###########################
## SET COLOR & SEPARATOR ##
###########################
declare -gr SPACER='----------------------------------------------------------------------------------------------------'
declare -gr E=$'\e[0;31m'			# (E) Error: highlighted text.
declare -gr W=$'\e[1;33m'			# (W) Warning: highlighted text.
declare -gr I=$'\e[0;32m'			# (I) Info: highlighted text.
declare -gr B=$'\e[1m'				# B for Bold.
declare -gr R=$'\e[0m'				# R for Reset.

###############################
## CHECK ELEVATED PRIVILEGES ##
###############################
if [[ "$(whoami)" != "root" ]]
	then
		echo
		echo "${E}Script must be run with root privileges! Execution will abort now, please run script again as root user (or use sudo).${R}"
		echo
		exit 1
	fi

####################
## SCRIPT OPTIONS ##
####################
function setOptions () {

  # List Options
	cat <<-END
		${SPACER}
		${B}${I}GNOME DESKTOP ENVIRONMENT INSTALLER SCRIPT${R}
		${I}This script has multiple options. Documentation available at:${R}
		${B}https://github.com/zjagust/gnome-desktop-environment-debian ${R}
		${B}https://zacks.eu/install-gnome-desktop-environment-on-debian-easy-guide ${R}
		${SPACER}
		The following options are available:
		 ${B}-h:${R} Print this help message
		 ${B}-i:${R} Install GNOME Desktop Environment
		  -> ${B}User name, first/last name and password must be supplied as arguments!${R}
		  -> ${B}EXAMPLE: $0 -i jdoe "John Doe" passpass${R}
		${SPACER}
	END
}

#######################
## NETWORK VARIABLES ##
#######################
INTERFACE_TYPE=$(< /etc/network/interfaces grep iface | grep -v loopback | awk '{print $4}')
INTERFACE_NAME=$(ip a | grep "2: " | awk '{print $2;}' | cut -d: -f1)
IP_ADDRESS=$(ip -br -c addr show "$INTERFACE_NAME" | awk '{print $3}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g")
GATEWAY=$(ip route show 0.0.0.0/0 | awk '{print $3}')
NAMESERVERS="8.8.8.8 8.8.4.4"

##########################
## DEBIAN VERSION CHECK ##
##########################

function debianVersion ()
{
	
	# Get release codename and version
	OS_VERSION=$(grep VERSION_ID /etc/os-release | awk -F '=' '{print $2}' | tr -d '"')

	# Do a version check
	if [[ "$OS_VERSION" -lt "11" ]]
	then
	    echo
		echo "${W}This script can only run on Debian version 11 (codename bullseye) or greater.${R}"
		echo "${E}Your Debian version is lower than that, thus script will abort now.${R}"
		echo
		exit 1
	fi

}

#####################################
## UPDATE & INSTALL GNOME PACKAGES ##
#####################################
function installGnome () {

	# Update APT
	apt update

	# Install GNOME Packages
	if [[ "$OS_VERSION" == "11" ]]
	then
		DEBIAN_FRONTEND=noninteractive aptitude install -y -R alsa-utils chrome-gnome-shell cups-common dbus-x11 \
		dconf-editor firefox-esr fuse_ fuse3 gdm3 gjs gkbd-capplet gnome-applets gnome-control-center gnome-disk-utility \
		gnome-keyring gnome-session gnome-shell-extension-dashtodock gnome-shell-extensions gnome-terminal gnome-tweaks \
		mutter nautilus nautilus-extension-gnome-terminal network-manager-gnome rclone sane-airscan sane-utils seahorse \
		software-properties-gtk sudo xdg-desktop-portal xdg-desktop-portal-gtk xdg-user-dirs
	else
		DEBIAN_FRONTEND=noninteractive aptitude install -y -R alsa-utils chrome-gnome-shell cups-common \
		dbus-x11 dconf-editor firefox-esr fuse_ fuse3 gdm3 gjs gkbd-capplet gnome-applets gnome-control-center \
		gnome-disk-utility gnome-keyring gnome-session gnome-shell-extension-dashtodock gnome-shell-extensions \
		gnome-shell-extensions-extra gnome-shell-extension-manager gnome-terminal gnome-tweaks mutter nautilus \
		nautilus-extension-gnome-terminal network-manager-gnome power-profiles-daemon rclone sane-airscan sane-utils \
		seahorse software-properties-gtk sudo xdg-desktop-portal xdg-desktop-portal-gnome xdg-desktop-portal-gtk \
		xdg-user-dirs
	fi

}

#########################
## CREATE DESKTOP USER ##
#########################
function createDesktopUser () {

	# Create User
	useradd -m -c "$3" -G adm,cdrom,sudo,dip,plugdev -s /bin/bash "$2"

	# Create password
	usermod --password "$(echo "$4" | openssl passwd -1 -stdin)" "$2"

	# SUDO Set
	echo "$2 ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/"$2"

	# Extend $PATH
	printf "\n# Extend \$PATH variable\nexport PATH=\$PATH:/usr/local/sbin:/usr/sbin:/sbin" >> /home/"$2"/.bashrc

}

#############################################
## RECONFIGURE NETWORK FOR NETWORK MANAGER ##
#############################################
function reconfigureInterfaces () {

	# Completely comment interfaces file
	sed -i 's/^#*/#/g' /etc/network/interfaces

}

#########################
## ENABLE DASH-TO-DOCK ##
#########################
function dashToDock () {

	# Set @reboot cron
	echo "@reboot /home/$2/dash-to-dock.sh" | crontab -u "$2" -

	# Set script
	if [[ "$INTERFACE_TYPE" == "static" ]];
	then
		ifconfig $INTERFACE_NAME down
		nmcli con add type ethernet con-name InterWebz ifname $INTERFACE_NAME ip4 $IP_ADDRESS gw4 $GATEWAY
		nmcli con mod InterWebz ipv4.dns "$NAMESERVERS"
		nmcli dev set $INTERFACE_NAME managed yes
		systemctl restart NetworkManager.service
		nmcli con up InterWebz ifname $INTERFACE_NAME
		cat > /home/"$2"/dash-to-dock.sh <<- EOF
		#!/bin/bash -i
		ssh-keygen -b 4096 -t rsa -f /home/"$2"/.ssh/id_rsa -q -N ""
		dbus-launch gnome-extensions enable dash-to-dock@micxgx.gmail.com
		killall -SIGQUIT gnome-shell
		dbus-launch gsettings set org.gnome.shell.extensions.dash-to-dock autohide false
		dbus-launch gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
		xdg-user-dirs-update
		crontab -u $2 -r
		rm -rf /home/$2/dash-to-dock.sh
		EOF
		chown "$2":"$2" /home/"$2"/dash-to-dock.sh
		chmod 0755 /home/"$2"/dash-to-dock.sh
		
		# Set a proper line endings - just in case
		sed -i 's/\r$//' /home/"$2"/dash-to-dock.sh
		
		# Finish and reboot
		echo "${SPACER}"
		echo "${I}GNOME Desktop Environment is now installed, will reboot.${R}"
		echo "${SPACER}"
		sleep 5 && shutdown -r now
	else
		cat > /home/"$2"/dash-to-dock.sh <<- EOF
		#!/bin/bash -i
		ssh-keygen -b 4096 -t rsa -f /home/"$2"/.ssh/id_rsa -q -N ""
		dbus-launch gnome-extensions enable dash-to-dock@micxgx.gmail.com
		killall -SIGQUIT gnome-shell
		dbus-launch gsettings set org.gnome.shell.extensions.dash-to-dock autohide false
		dbus-launch gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
		xdg-user-dirs-update
		crontab -u $2 -r
		rm -rf /home/$2/dash-to-dock.sh
		EOF
		chown "$2":"$2" /home/"$2"/dash-to-dock.sh
		chmod 0755 /home/"$2"/dash-to-dock.sh
		
		# Set a proper line endings - just in case
		sed -i 's/\r$//' /home/"$2"/dash-to-dock.sh
		
		# Finish and reboot
		echo "${SPACER}"
		echo "${I}GNOME Desktop Environment is now installed, will reboot.${R}"
		echo "${SPACER}"
		sleep 5 && shutdown -r now
	fi

}

#################
## GET OPTIONS ##
#################

# No parameters
if [ $# -eq 0 ]; then
	setOptions
	exit 1
fi

# Execute
while getopts ":hi" option; do
	case $option in
		h) # Display help message
			setOptions
			exit
			;;
		i) # Install GNOME
			debianVersion
			installGnome
			createDesktopUser "$@"
			reconfigureInterfaces
			dashToDock "$@"
			;;
		\?) # Invalid options
			echo "Invalid option, will exit now."
			exit
			;;
	esac
done