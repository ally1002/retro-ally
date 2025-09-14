#!/bin/bash

# ===================================================================================
# POST-INSTALLATION SCRIPT FOR A PORTABLE ARCH LINUX SYSTEM FOR RETRO GAMES
# ===================================================================================


if [[ $EUID -ne 0 ]]; then
   echo "ERROR: This script must be run with sudo." 
   exit 1
fi

if [[ -z "$SUDO_USER" ]]; then
    REAL_USER=$(logname)
else
    REAL_USER=$SUDO_USER
fi

if [[ -z "$REAL_USER" ]]; then
    echo "ERROR: Could not determine the user."
    exit 1
fi

echo "INFO: Running setup for user: $REAL_USER..."
HOME_DIR="/home/$REAL_USER"

echo "INFO: Installing reflector to get the best mirrors..."
pacman -S --noconfirm --needed reflector

echo "INFO: Optimizing mirrorlist for the current location..."
reflector \
  --verbose \
  --protocol https \
  --age 12 \
  --latest 20 \
  --sort rate \
  --number 5 \
  --save /etc/pacman.d/mirrorlist

echo "INFO: Installing packages from the official repositories..."
pacman -Syu --noconfirm --needed \
    git base-devel \
    amd-ucode intel-ucode \
    mesa lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-radeon lib32-vulkan-radeon nvidia nvidia-utils lib32-nvidia-utils \
    pipewire pipewire-pulse pipewire-alsa \
    retroarch openbox xorg-server xorg-xinit alacritty firefox nautilus


echo "INFO: Re-installing GRUB for portability..."
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable

# WARNING: For encrypted systems, manually add the 'cryptdevice' boot
# parameter to /etc/default/grub before generating the config.

echo "INFO: Generating GRUB configuration..."
grub-mkconfig -o /boot/grub/grub.cfg


echo "INFO: Installing yay (AUR Helper)..."
sudo -u $REAL_USER bash -c '
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd -
    rm -rf yay
'

echo "INFO: Using yay to install EmulationStation-DE..."
sudo -u $REAL_USER yay -S --noconfirm emulationstation-de


echo "INFO: Copying configuration files to the user's home directory..."
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

echo "INFO: Creating default .config/ folder..."
sudo -u $REAL_USER mkdir -p $HOME_DIR/.config

echo "INFO: Copying all default configuration files..."
sudo -u $REAL_USER cp -r $SCRIPT_DIR/dotfiles/.* $HOME_DIR/
sudo -u $REAL_USER cp -r $SCRIPT_DIR/dotfiles/.config/* $HOME_DIR/.config/

echo "INFO: Ensuring correct ownership of all files in home directory..."
chown -R $REAL_USER:$REAL_USER $HOME_DIR


echo "INFO: Enabling essential services..."
systemctl enable NetworkManager.service

echo "-------------------------------------------------------------"
echo "INFO: Setup complete! You can now reboot the system."
echo "-------------------------------------------------------------"
