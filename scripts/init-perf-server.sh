#! /usr/bin/env bash

apt update -y
apt upgrade -y
apt install nginx curl iperf wrk -y
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj "/C=US/ST=WA/L=Redmond/O=Azure Cloud Partnership/CN=azure.csp.paloaltonetworks.com"
cat <<'EOF' > /etc/nginx/sites-available/default-ssl
server {
        listen 443 ssl default_server;
        listen [::]:443 ssl default_server;

        ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
        ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

        # Include a strong cipher suite to improve security
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
        ssl_ciphers EECDH+AESGCM:EDH+AESGCM;

        root /var/www/html;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                try_files $uri $uri/ =404;
        }
}
EOF
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
<title>$(hostname)</title>
</head>
<body>
<h1>$(hostname)</h1>
</body>
EOF
ln -s /etc/nginx/sites-available/default-ssl /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx
