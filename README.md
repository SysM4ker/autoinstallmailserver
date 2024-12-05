# Automatic installation of Poste.io

This project allows you to easily install a mail server using [poste.io](https://poste.io) (which runs on a docker). This README provides instructions for manual installation as well as instructions for using the automatic installation script.

## Table of contents
  - [Requirements](#requirements)
  - [Automatic Installation](#automatic-installation)
  - [Manuel Installation](#manuel-installation)
  - [Configuration](#configuration)
  - [Error Management](#error-management)
  - [Sources](#sources)
  - [Contributions](#contributions)
	

---
 
## Requirements

  - A VPS (Virtual Private Server) Or Server
  - Root Permissions
  - That's all it takes

---

## Automatic Installation

To install it automatically, it's quite simple. You just need to install the script with the following command, give it execution rights and then run it. 

```
wget https://raw.githubusercontent.com/SysM4ker/autoinstallmailserver/refs/heads/main/install.sh
sudo chmod +x install.sh
./install.sh
```
Once done, simply follow the instructions given in the terminal.

---

## Manuel Installation

To start with, we're going to update the packages and install all the packages we'll need for the mail server.

```
sudo apt update && sudo apt upgrade
sudo apt install cron nginx snapd net-tools ca-certificates curl

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
 sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

```
Once all this is done and no errors are displayed, simply install poste.io with docker
But first we're going to create the file in which the mail service will be stored.

`mkdir /home/mail`

```
docker run -d --net=host -e TZ=Europe/Paris -v /home/mail:/data --name "mailserver" -h "mail.example.com" -e "HTTP_PORT=8080" -e "HTTPS_PORT=4433" -t analogic/poste.io
```
Of course, you must replace the TimeZone with the server's TimeZone and the domain name with your domain name.
You are also free to make this service work on other ports and to name the docker as you wish.

You can ensure that the service is running perfectly with the following command:
```
sudo docker ps
```
If it doesn't display the docker, it hasn't been launched.
```
sudo docker ps -a #Allows you to see all dockers, even those who are not launched
```
To close or open a docker
```
sudo docker stop $NAME_DOCKER
sudo docker start $NAME_DOCKER
```
Once this is working perfectly, we just need to configure nginx 

To configure nginx, simply install the configuration I've already prepared [here](https://raw.githubusercontent.com/SysM4ker/autoinstallmailserver/refs/heads/main/confpostenginx) with the following command:
```
sudo wget -O /etc/nginx/sites-available/mail https://raw.githubusercontent.com/SysM4ker/autoinstallmailserver/refs/heads/main/confpostenginx
sudo ln -s /etc/nginx/sites-available/mail /etc/nginx/sites-enabled/
sudo nginx -s reload
```
Don't forget to change the example domain name to your own in the nginx configuration with the command : 
`sudo nano /etc/nginx/sites-available/mail`

Normally once all this is done and the [DNS configured](#configuration) you can access your mail service with the domain name. The problem is that there is no HTTPS and to configure it nothing could be simpler:
```
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
sudo certbot --nginx
```
To do this, we used [certbot](https://certbot.eff.org/), so all that's left to do is follow the steps.

However, when you restart the server, you have to restart the docker, and since we're lazy, we want this to be done automatically, and thanks to the crontab, we can do it. 
```
crontab -e #Select the editor of your choice
#And add this line to the last line
	@reboot sudo docker start $NAME_DOCKER
```
After all that, everything should work perfectly if you have forgotten to configure [DNS redirections](#configuration). 
If you don't receive or can't send e-mail, go [here](#error-management)

---



## For firewall configuration, here are all the  ports used :

| Port      |                                                                                                                                                                                                                                                                                                                                                                    |
| --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 25        | **SMTP** - mostly processing incoming mails from remote mail servers                                                                                                                                                                                                                                                                                               |
| 80, 8080  | **HTTP** - redirect to https (see options) and authentication for Let's encrypt service                                                                                                                                                                                                                                                                            |
| 110       | **POP3** - standard protocol for accessing mailbox, STARTTLS is required before client auth                                                                                                                                                                                                                                                                        |
| 143       | **IMAP** - standard protocol for accessing mailbox, STARTTLS is required before client auth                                                                                                                                                                                                                                                                        |
| 443, 4433 | **HTTPS** - access to administration or webmail client                                                                                                                                                                                                                                                                                                             |
| 465       | **SMTPS** - Legacy SMTPs port                                                                                                                                                                                                                                                                                                                                      |
| 587       | **MSA** - SMTP port primarily used by email clients after STARTTLS and auth                                                                                                                                                                                                                                                                                        |
| 993       | [**IMAPS**](https://en.wikipedia.org/wiki/Internet_Message_Access_Protocol) - alternative port for IMAP with encryption from the start of the connection                                                                                                                                                                                                           |
| 995       | [**POP3S**](https://en.wikipedia.org/wiki/Sieve_(mail_filtering_language)) - POP3 port with encryption from the start of the connection                                                                                                                                                                                                                            |
| 4190      | **Sieve** - remote sieve settings                                                                                                                                                                                                                                                                                                                                  |
| 22, 2222  | [**SSH**](https://en.wikipedia.org/wiki/Secure_Shell) - is a [cryptographic](https://en.wikipedia.org/wiki/Cryptography "Cryptography") [network protocol](https://en.wikipedia.org/wiki/Network_protocol "Network protocol") for operating [network services](https://en.wikipedia.org/wiki/Network_service "Network service") securely over an unsecured network |

```
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 8080
sudo ufw allow 4433
sudo ufw allow 25     # SMTP
sudo ufw allow 587    # SMTP sécurisé (submission)
sudo ufw allow 993    # IMAP sécurisé
sudo ufw allow 995    # POP3 sécurisé
sudo ufw allow 143    # IMAP
sudo ufw allow 4190   # POP3S
sudo ufw allow 465    # SMTPS

sudo ufw enable

sudo ufw status verbose  # Check firewall status and rules applied

```

For even greater security, you can limit the number of SSH connections to prevent brute force attacks:
`sudo ufw limit ssh`

Delete a rule buy port or service:
`sudo ufw delete allow $port`

# Error

`netstat -nlp | grep 25`
`sudo systemctl stop exim4`
`sudo systemctl disable exim4`


# Check DNS settings
Check the A record: Make sur that the ** $url ** domain points correctly to the IP address ** $ip ** .
You can use the following command to check : 
`nslookup $url`
#### Test port 25: Try checking the connection to port 25 using telnet or nc from your machine or another machine:
`nc -zv $ip`

# Check firewall rules
Make sure there are no firewall rules on the server blocking port 25.
You can check iptables or ufw rules as mentioned above.
Here's a reminder:
`sudo iptables -L -n` or `sudo ufw status`

# Check network connectivity
Test connectivity to IP: Try pinging the IP address from your machine:
`ping $ip`
## Check SMTP server configuration 
Make sur the SMTP server is running and listening on port 25.
In the Poste.io Docker container, check the SMTP configuration and make sur everything is set up correctly.

```
docker exec -it $mailserver /bin/bash
netstat -tuln | grep 25
```


```
### 3. Contacte le support technique

C'est souvent la meilleure option. Voici comment procéder :

- **Prépare les informations nécessaires** : Avant de les contacter, note les détails suivants :
    
    - L'adresse IP de ton serveur.
    - Le domaine que tu utilises.
    - Les tests que tu as réalisés (comme `ping`, `telnet`, etc.).
    - Les messages d'erreur que tu as reçus.
- **Envoie un ticket ou appelle le support** : Demande s'il y a des restrictions sur le port 25 ou si des configurations spécifiques sont requises pour le fonctionnement de ton serveur SMTP. Pose des questions comme :
    
    - Le port 25 est-il ouvert sur mon serveur ?
    - Y a-t-il des restrictions concernant l'envoi d'e-mails ?
    - Existe-t-il un port alternatif pour le SMTP (par exemple, port 587) ?
```

https://docs.pulseheberg.com/en/article/i-cant-send-emails-from-my-server-1lir99q/




# Sources : 
  - [Poste.io Docs](https://poste.io/doc/)
  - [Docker download](https://docs.docker.com/engine/install/debian/#install-using-the-repository) 
  - [Snap download](https://snapcraft.io/docs/installing-snap-on-debian)
  - [Certbot download](https://certbot.eff.org/instructions?ws=nginx&os=snap)
  - [Installation d'un SERVEUR MAIL COMPLET sous Debian avec Docker](https://www.youtube.com/watch?v=pcSV1-FX56Q) - [Github README.md](https://github.com/TheodoricSoff/Serveur-mail/blob/main/README.md)

