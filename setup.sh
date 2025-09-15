#!/bin/bash

# ===================================================================================
# POST-INSTALLATION SCRIPT FOR A PORTABLE ARCH LINUX SYSTEM FOR RETRO GAMES
# ===================================================================================

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


if [[ $EUID -ne 0 ]]; then
  printf "${RED}ERROR: This script must be run with sudo.${NC}\n"
  exit 1
fi

if [[ -z "$SUDO_USER" ]]; then
  REAL_USER=$(logname)
else
  REAL_USER=$SUDO_USER
fi

if [[ -z "$REAL_USER" ]]; then
  printf "${RED}ERROR: Could not determine the user.${NC}\n"
  exit 1
fi

printf "${BLUE}INFO: Running setup for user: ${YELLOW}%s...${NC}\n" "$REAL_USER"
HOME_DIR="/home/$REAL_USER"


printf "${BLUE}INFO: Enabling the [multilib] repository...${NC}\n"
if grep -q "^\[multilib\]" /etc/pacman.conf; then
    printf "${GREEN}INFO: [multilib] repository is already enabled.${NC}\n"
else
    sudo sed -i "/^#\[multilib\]/,/^#Include/s/^#//" /etc/pacman.conf
    printf "${GREEN}SUCCESS: [multilib] repository has been enabled.${NC}\n"
fi

printf "${BLUE}INFO: Synchronizing package databases...${NC}\n"
sudo pacman -Syu


printf "${BLUE}INFO: Installing reflector to get the best mirrors...${NC}\n"
pacman -S --noconfirm --needed reflector

printf "${BLUE}INFO: Optimizing mirrorlist for the current location...${NC}\n"
reflector \
  --verbose \
  --protocol https \
  --age 12 \
  --latest 20 \
  --sort rate \
  --number 5 \
  --save /etc/pacman.d/mirrorlist


printf "${BLUE}INFO: Installing packages from the official repositories...${NC}\n"
pacman -Syu --noconfirm --needed \
  git base-devel \
  amd-ucode intel-ucode \
  mesa lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-radeon lib32-vulkan-radeon nvidia nvidia-utils lib32-nvidia-utils \
  pipewire pipewire-pulse pipewire-alsa \
  retroarch openbox xorg-server xorg-xinit alacritty firefox nautilus


printf "${BLUE}INFO: Re-installing GRUB for portability...${NC}\n"
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable

printf "${YELLOW}WARNING: For encrypted systems, manually add the 'cryptdevice' boot parameter to /etc/default/grub before generating the config.${NC}\n"

printf "${BLUE}INFO: Generating GRUB configuration...${NC}\n"
grub-mkconfig -o /boot/grub/grub.cfg


printf "${BLUE}INFO: Installing yay (AUR Helper)...${NC}\n"
sudo -u $REAL_USER bash -c '
  cd /tmp
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  cd -
  rm -rf yay
  cd ~
'

printf "${BLUE}INFO: Using yay to install EmulationStation-DE...${NC}\n"
sudo -u $REAL_USER yay -S --noconfirm emulationstation-de


printf "${BLUE}INFO: Copying configuration files to the user's home directory...${NC}\n"
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

printf "${BLUE}INFO: Creating default .config/ folder...${NC}\n"
sudo -u $REAL_USER mkdir -p $HOME_DIR/.config

printf "${BLUE}INFO: Copying all default configuration files...${NC}\n"
sudo -u $REAL_USER cp -r $SCRIPT_DIR/dotfiles/.* $HOME_DIR/
sudo -u $REAL_USER cp -r $SCRIPT_DIR/dotfiles/.config/* $HOME_DIR/.config/

printf "${BLUE}INFO: Ensuring correct ownership of all files in home directory...${NC}\n"
chown -R $REAL_USER:$REAL_USER $HOME_DIR


printf "${BLUE}INFO: Enabling essential services...${NC}\n"
systemctl enable NetworkManager.service

printf "${GREEN}-------------------------------------------------------------${NC}\n"
printf "${GREEN}INFO: Setup complete! You can now reboot the system.${NC}\n"
printf "${GREEN}-------------------------------------------------------------${NC}\n"
