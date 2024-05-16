
#!/bin/bash

# Install Git (if not already installed)
sudo apt update
sudo apt install -y git

# Prompt the user for GitHub username
read -p "Enter your GitHub username: " username

# Prompt the user for email address
read -p "Enter your email address for GitHub: " email

# Set the username and email address in Git
git config --global user.name "$username"
git config --global user.email "$email"

# Optionally, set a default text editor for Git
git config --global core.editor "nano"

# Generate SSH keys (if not already generated)
ssh-keygen -t rsa -b 4096 -C "$email"

# Add SSH key to SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

# Copy SSH public key to clipboard
sudo apt install -y xclip  # Install xclip if not already installed
xclip -sel clip < ~/.ssh/id_rsa.pub

# Provide instructions to the user
echo "SSH public key copied to clipboard. Now you need to add it to your GitHub account."
echo "Please go to your GitHub Settings > SSH and GPG keys, and add the SSH public key."

