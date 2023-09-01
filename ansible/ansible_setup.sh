#! /bin/bash

# Ansible is python based
sudo apt install python3 python3-pip -y

# Always make sure that the executables point to v3 and not v2
python -V 
pip --version

# Install & create virtualenv 
pip install virtualenv
if [ ! -d "$(pwd)/venv" ]
then
  python -m venv $(pwd)/venv
fi
source $(pwd)/venv/bin/activate

# Install dependencies in venv
pip install -r requirements.txt
ansible-galaxy install -r requirements.yml