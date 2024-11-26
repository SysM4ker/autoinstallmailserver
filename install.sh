#!/bin/bash

#Complete machine update
apt -y update && apt -y upgrade

#install all the important things for a mail server
apt install cron nginx snapd net-tools -y

#https://docs.docker.com/engine/install/debian/#install-using-the-repository
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
# To install the latest version, run:
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

mkdir /home/mail

#Install poste.io with docker
docker run -d --net=host -e TZ=Europe/Paris -v /home/mail:/data --name "mailserver" -h "mail.example.com" -e "HTTP_PORT=8080" -e "HTTPS_PORT=4433" -e "DISABLE_CLAMAV=TRUE" -t analogic/poste.io

#-e "DISABLE_CLAMAV=TRUE" To disable ClamAV, it is useful for low mem usage.
#-e "DISABLE_RSPAMD=TRUE" To disable Rspamd, it is useful for low mem usage.


##Configuration nginx

wget -P /etc/nginx/site-available/ -O mail https://raw.githubusercontent.com/SysM4ker/autoinstallmailserver/refs/heads/main/confpostenginx
ln -s /etc/nginx/sites-available/mail /etc/nginx/sites-enabled/
sudo nginx -s reload

###########

#install certbot for https
#https://certbot.eff.org/instructions?ws=nginx&os=snap
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
sudo certbot --nginx