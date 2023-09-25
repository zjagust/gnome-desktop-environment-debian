# GNOME Desktop Environment on Debain - Automated Install
This script will automate the installation of the GNOME Desktop Environment on Debian. For more details, please consult the following article:

* [Install GNOME Desktop Environment on Debian: Easy Guide](https://zacks.eu/install-gnome-desktop-environment-on-debian-easy-guide)

Tested on:

* Debian 11 (Bullseye)
* Debian 12 (Bookworm)

**The script is suited for Debain version 11 (Bullseye) or greater. It will require modifications for older versions of Debian systems.**

## Usage
This script will run on a minimal installation of Debian operating system, or on top of a Debain Server installation (should you have such a "strange" need). It will install a bare minimum of packages required to run the GNOME Desktop Environment, without any additional applications. To achieve a minimum "prerequisites", please consult the following articles and repositories:

* [Home/Small Office – Debian Server](https://zacks.eu/home-small-office-debian-server/)
* [Home/Small Office – Debian Server Initial Customization](https://zacks.eu/debian-server-initial-customization/)
* [Initial Customization for Debian Server minimal installations](https://github.com/zjagust/debian-server-initial-customization)

### Script Installation
You can clone this repository anywhere on your computer (or virtual machine), i.e.:

```bash
cd /tmp && git clone https://github.com/zjagust/gnome-desktop-environment-debian.git
```

Once repository is cloned, execute the following:

```bash
cd /tmp/gnome-desktop-environment-debian
. gnome-debian-autoinstall.sh
```

Let the script do its work!