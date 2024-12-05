#!/bin/bash

echo -e "\033[0;32m"
echo "
██████   ██████  ███████ ████████ ███████    ██  ██████  
██   ██ ██    ██ ██         ██    ██         ██ ██    ██ 
██████  ██    ██ ███████    ██    █████      ██ ██    ██ 
██      ██    ██      ██    ██    ██         ██ ██    ██ 
██       ██████  ███████    ██    ███████ ██ ██  ██████
"

#Complete machine update
sudo apt -y update && sudo apt -y upgrade

#install all the important things for a mail server
sudo apt install cron nginx snapd net-tools -y

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
CONTAINER_NAME="mailserver"

#
# echo "Your domain name example mail.domainname.tld"
# read domain
read -p "Enter your domain (ex: mail.exemple.tld) : " DOMAIN

#Install poste.io with docker
sudo docker run -d --net=host -e TZ=Europe/Paris -v /home/mail:/data --name "mailserver" -h "$DOMAIN" -e "HTTP_PORT=8080" -e "HTTPS_PORT=4433" -e "DISABLE_CLAMAV=TRUE" -t analogic/poste.io

#-e "DISABLE_CLAMAV=TRUE" To disable ClamAV, it is useful for low mem usage.
#-e "DISABLE_RSPAMD=TRUE" To disable Rspamd, it is useful for low mem usage.

#Crontabe configuration so that the docker can be launched on startup
(crontab -l 2>/dev/null; echo "@reboot sudo docker start $CONTAINER_NAME") | crontab -

##Configuration nginx

sudo wget -O /etc/nginx/sites-available/mail https://raw.githubusercontent.com/SysM4ker/autoinstallmailserver/refs/heads/main/confpostenginx
sudo sed -i "s/mail\.domaine\.tld/$DOMAIN/g" /etc/nginx/sites-available/mail
sudo ln -s /etc/nginx/sites-available/mail /etc/nginx/sites-enabled/
sudo nginx -s reload

###########

#install certbot for https
#https://certbot.eff.org/instructions?ws=nginx&os=snap

while true; do
    read -p "Do you want to install certboot?(for https) [Y/n] " CHOICE
    CHOICE=${CHOICE:-Y}  # If the user does not enter anything, it is considerred to be Y
    case $CHOICE in
        [Yy]* ) 
            echo "You chose to continue."
            sudo snap install --classic certbot
            sudo ln -s /snap/bin/certbot /usr/bin/certbot
            sudo certbot --nginx
            break
            ;;
        [Nn]* ) 
            echo "You have decided not to install certboot."
            exit 0
            ;;
        * ) 
            echo "Please enter Y for Yes or N for No."
            ;;
    esac
done

echo "Your site is available at this address $DOMAIN"