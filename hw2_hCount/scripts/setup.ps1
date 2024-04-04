# Setup Python virtual environment
Write-Host "Setting up Python virtual environment..."
C:\Python312\python.exe -m venv venv

# Activate Python virtual environment
Write-Host "Activating Python virtual environment..."
.\venv\Scripts\Activate.ps1

# Install Python packages
Write-Host "Installing Python packages..."
pip install -r requirements.txt

Write-Host "Done."
