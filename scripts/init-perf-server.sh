#! /usr/bin/env bash

SSL_KEY_FILE=/etc/ssl/private/nginx-selfsigned.key
SSL_CRT_FILE=/etc/ssl/certs/nginx-selfsigned.crt
SSL_SUBJECT="/C=US/ST=WA/L=Redmond/O=Azure Cloud Partnership/CN=azure.csp.paloaltonetworks.com"

HTTP_1G_FILE=/var/www/html/1G

set -x

apt update -y
apt upgrade -y
apt install nginx iperf wrk -y

# Create certificate for https
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${SSL_KEY_FILE} -out ${SSL_CRT_FILE} -subj "${SSL_SUBJECT}"
cat <<EOF > /etc/nginx/sites-available/default-ssl
server {
        listen 443 ssl default_server;
        listen [::]:443 ssl default_server;

        ssl_certificate ${SSL_CRT_FILE};
        ssl_certificate_key ${SSL_KEY_FILE};

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
        ssl_ciphers EECDH+AESGCM:EDH+AESGCM;

        root /var/www/html;

        index index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
                try_files \$uri \$uri/ =404;
        }
}
EOF

# Create basic HTML page
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
<title>$(hostname)</title>
</head>
<body>
<h1>Host: $(hostname)</h1>
<h1>PCI devices</h1>
<pre>
$(lspci -nn)
</pre>
<h1>Links</h1>
<pre>
$(ip link)
</pre>
</body>
EOF

# Create a 1G text file with random characters
dd if=/dev/urandom of=${HTTP_1G_FILE} bs=1G count=1

# Enable https
ln -s /etc/nginx/sites-available/default-ssl /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx

# Open ports for iperf
ufw allow 5001/tcp
ufw allow 5001/udp

