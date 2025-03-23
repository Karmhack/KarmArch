##### A SUPPRIMER, OK pour GITHUB#####
#!/bin/bash

## Install script to setup a fresh Arch Linux installation

# Enable strict error handling and undefined variable detection
set -eu
# Update the system and upgrade all packages without confirmation
sudo pacman -Suy --noconfirm



# Function to install essential packages
install_packages() {
    echo "Installing packages..."
    # Install the required packages with --noconfirm flag to avoid prompts
    sudo pacman -S --noconfirm --needed \
        openssh noto-fonts-cjk hplip curl cups cups-pdf cups-pk-helper \
        foomatic-db foomatic-db-engine foomatic-db-gutenprint-ppds \
        foomatic-db-nonfree foomatic-db-nonfree-ppds foomatic-db-ppds \
        gutenprint libcups vlc nmap git python-pip timeshift bluez zip unzip \
        base-devel make flatpak openvpn touchegg libreoffice-still chromium \
        avahi nss-mdns nano
}



# Function to configure printer services
configure_printers() {
    echo "Configuring printers..."
    # Start and enable the CUPS (printing service) socket
    sudo systemctl start cups.socket
    sudo systemctl enable cups.socket
    
    # Start and enable the Avahi service (for mDNS and service discovery)
    sudo systemctl start avahi-daemon
    sudo systemctl enable avahi-daemon
    
    # Backup and modify the /etc/nsswitch.conf file to enable mDNS
    NSSWITCH_CONF="/etc/nsswitch.conf"
    sudo cp "$NSSWITCH_CONF" "$NSSWITCH_CONF.bak"
    sudo sed -i 's/^hosts:.*/hosts: mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns/' "$NSSWITCH_CONF"
    echo "Printer configuration complete."
}



# Function to enable and start Touchegg (gesture recognition software)
setup_touchegg() {
    echo "Enabling Touchegg..."
    # Enable Touchegg to start on boot and start the service
    sudo systemctl enable touchegg.service
    sudo systemctl start touchegg
}



# Function to install Flatpak applications
install_flatpak_apps() {
    echo "Installing Flatpak applications..."
    # Add Flathub repository if it doesn't already exist
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    
    # Define a list of applications to install from Flathub
    apps=( "org.torproject.torbrowser-launcher" "com.spotify.Client" "com.discordapp.Discord" "net.cozic.joplin_desktop" )
    
    # Loop through the app list and install each one
    for app in "${apps[@]}"; do
        sudo flatpak install flathub "$app" -y
    done
    echo "Flatpak application installation complete."
}



# Function to configure OpenVPN
setup_openvpn() {
    echo "Configuring OpenVPN..."
    # Define URL for the update script and necessary configuration files
    SCRIPT_URL="https://raw.githubusercontent.com/jonathanio/update-systemd-resolved/master/update-systemd-resolved"
    SCRIPT_PATH="/etc/openvpn/update-resolv-conf"
    CLIENT_CONF="/etc/openvpn/client/client.conf"
    POLKIT_RULES="/etc/polkit-1/rules.d/00-openvpn-resolved.rules"
    
    # Download the script
    sudo curl -o $SCRIPT_PATH $SCRIPT_URL
    # Make the script executable
    sudo chmod +x $SCRIPT_PATH
    
    # Append necessary configuration to the OpenVPN client configuration file
    sudo bash -c "cat >> $CLIENT_CONF << 'EOF'
script-security 2
setenv PATH /usr/bin
up $SCRIPT_PATH
down $SCRIPT_PATH
down-pre
dhcp-option DOMAIN-ROUTE .
EOF"
    
    # Create a Polkit rule to allow OpenVPN to modify system settings
    sudo bash -c "cat > $POLKIT_RULES << 'EOF'
polkit.addRule(function(action, subject) {
    if (action.id.match(/org.freedesktop.resolve1.set-.*/)) {
        if (subject.user == 'openvpn') {
            return polkit.Result.YES;
        }
    }
});
EOF"
    
    # Enable and start the systemd-resolved service
    sudo systemctl enable --now systemd-resolved
    echo "OpenVPN configuration complete."
}



# Function to install yay (AUR helper) and AUR packages
install_yay_and_aur() {
    echo "Installing yay and AUR packages..."
    # Install necessary dependencies and clone the yay repository from AUR
    sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
    
    # Install a list of AUR packages using yay
    packages=("visual-studio-code-bin" "vmware-keymaps" "vmware-workstation")
    for package in "${packages[@]}"; do
        yay -S "$package" --noconfirm
    done
    echo "AUR package installation complete."
}



# Function to create a list of GNOME extensions to install later
list_gnome_extensions() {
    echo "Creating list of GNOME extensions to install manually..."
    cat <<EOL >  ~/Documents/list_extensions.txt
astra-monitor
burn-my-windows@schneegans.github.com
desktop-cube@schneegans.github.com
ip-finder@lujun9972
lan-ip-address@lujun9972
transparent-top-bar-adjustable@aleph168
x11-gestures@joseexposito.github.com
EOL
}



# Function to configure the GNOME dock with favorite applications
setup_dock() {
    echo "Configuring GNOME dock..."
    # List of applications to add to the GNOME dock
    apps=(
        "chromium.desktop" "org.gnome.Console.desktop" "code.desktop"
        "org.gnome.Nautilus.desktop" "org.gnome.TextEditor.desktop"
        "vmware-workstation.desktop" "net.cozic.joplin_desktop.desktop"
        "com.discordapp.Discord.desktop" "com.spotify.Client.desktop"
        "org.gnome.Software.desktop" "org.gnome.Settings.desktop"
    )
    
    # Remove all current favorite apps from the GNOME dock
    gsettings set org.gnome.shell favorite-apps "[]"
    
    # Add the new favorite applications to the dock
    new_favorites=$(printf "'%s', " "${apps[@]}")
    new_favorites="[${new_favorites%, }]"
    gsettings set org.gnome.shell favorite-apps "$new_favorites"
    echo "GNOME dock configured."
}



# Function to create a TODO list for configuring Chromium later
chromium_TODO() {
    echo "Creating TODO list for Chromium setup..."
    cat <<EOL >  ~/Documents/chromium_todo.txt
install Bitwarden, ublock, webrtc control
EOL
}



# Function to install and configure Fastfetch (system information tool)
setup_fastfetch() {
    echo "Installing and configuring Fastfetch..."
    # Check if Fastfetch is already installed, if not, install it
    if ! command -v fastfetch &> /dev/null; then
        sudo pacman -S fastfetch --noconfirm
    fi
    # Add Fastfetch to the .bashrc file if it's not already there
    grep -q "fastfetch" ~/.bashrc || echo "fastfetch" >> ~/.bashrc
}



# Execution of all functions
echo "Starting installation script..."
install_packages
configure_printers
setup_touchegg
install_flatpak_apps
setup_openvpn
install_yay_and_aur
list_gnome_extensions
setup_dock
chromium_TODO
setup_fastfetch
echo "Installation complete."
