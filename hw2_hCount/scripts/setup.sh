#!/bin/bash
# Install Python virtual environment
echo "Installing Python virtual environment..."
sudo apt install python3.10-venv

# Setup Python virtual environment
echo "Setting up Python virtual environment..."
python3.10 -m venv venv

# Activate Python virtual environment
echo "Activating Python virtual environment..."
source venv/bin/activate

# Install Python packages
echo "Installing Python packages..."
pip install -r requirements.txt

echo "Setup complete!"
