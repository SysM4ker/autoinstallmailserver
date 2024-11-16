
```
apt install cron perl nginx fail2ban snapd net-tools
```

Add users 
```
adduser $username
usermod -aG sudo $username
mkdir /home/$mail
```
To prevent connection via Root
```
vim /etc/ssh/sshd_config
	PermitRootLogin no
systemctl restart ssh.service
```

Install docker
```
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

# Install docker
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Install poste.io with docker
```
docker run --net=host -e TZ=Europe/Paris -v /your-data-dir/data:/data --name "mailserver" -h "mail.example.com" -e "HTTP_PORT=8080" -e "HTTPS_PORT=4433" -t analogic/poste.io
```
- **-e "DISABLE_CLAMAV=TRUE"** To disable ClamAV, it is useful for low mem usage.
    
- **-e "DISABLE_RSPAMD=TRUE"** To disable Rspamd, it is useful for low mem usage.


```
docker ps -a
docker rm $nameservice
```
Use certbot for https
```

```


Conf nginx 
```
vim /etc/nginx/site-available/mail
server {
    listen 80;
    listen [::]:80;
    server_name mail.domaine.tld;

    proxy_buffering off;
    proxy_http_version 1.1;
    proxy_cache_bypass $http_upgrade;

    proxy_set_header Host               $host;
    proxy_set_header Connection         "upgrade";
    proxy_set_header Upgrade            $http_upgrade;
    proxy_set_header X-Real-IP          $remote_addr;
    proxy_set_header X-Forwarded-Server $host;
    proxy_set_header X-Forwarded-Proto  $scheme;
    proxy_set_header X-Forwarded-Port   $server_port;
    proxy_set_header X-Forwarded-Host   $host:$server_port;
    proxy_set_header X-Forwarded-For    $proxy_add_x_forwarded_for;

    location / {
        proxy_pass https://0.0.0.0:4433/;
    }
}

```

`ln -s /etc/nginx/sites-available/mail /etc/nginx/sites-enabled/`
`nginx -s reload`



To make the docker launch itself on startup
```
crontab -e
	@reboot docker start $dockernameservice
```


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


no-reply@ozzzint.fr


# Source :
  - [Installation d'un SERVEUR MAIL COMPLET sous Debian avec Docker](https://www.youtube.com/watch?v=pcSV1-FX56Q) - [Github README.md](https://github.com/TheodoricSoff/Serveur-mail/blob/main/README.md)
  - [Docker download](https://docs.docker.com/engine/install/debian/#install-using-the-repository) 
  - [Snap download](https://snapcraft.io/docs/installing-snap-on-debian)
  - [Certbot download](https://certbot.eff.org/instructions?ws=nginx&os=snap)
  - [Poste.io Docs](https://poste.io/doc/)
  - [How to add Users on Debian 12](https://linuxize.com/post/how-to-add-and-delete-users-on-debian/)