#!/bin/bash

echo "Starting Nginx VPS setup..."

# update system packages
# echo -e "\n--- Updating system packages ---"
# sudo apt update -y
# sudo apt upgrade -y

# check if apt update/upgrade was successful
# if [ $? -ne 0 ]; then
#    echo "Error: Failed to update or upgrade system packages. Exiting."
#    exit 1
# fi

# install nginx
echo -e "\n--- Installing Nginx ---"
sudo apt install nginx -y

# check if nginx installation was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to install Nginx. Exiting."
    exit 1
fi

echo "Nginx installed successfully."

# configure firewall
echo -e "\n--- Configuring UFW firewall ---"

# install UFW if not already installed
sudo apt install ufw -y

# allow OpenSSH for remote access
sudo ufw allow OpenSSH

# allow HTTP and HTTPS traffic
sudo ufw allow 'Nginx HTTP'
sudo ufw allow 'Nginx HTTPS'

# enable UFW
sudo ufw enable <<EOF
y
EOF

# Check UFW status
echo "UFW status:"
sudo ufw status verbose

echo "UFW configured and enabled."

# create a basic website directory structure for a default site (PURE TESTING)
echo -e "\n--- Setting up default website directory ---"
DEFAULT_DOMAIN="librebucket.standardgroup.dedyn.io"
DEFAULT_SITE_ROOT="/var/www/$DEFAULT_DOMAIN/html"

sudo mkdir -p "$DEFAULT_SITE_ROOT"

# set ownership to the current user and web group, and appropriate permissions
sudo chown -R "$USER":"$USER" "$DEFAULT_SITE_ROOT"
sudo chmod -R 755 "$DEFAULT_SITE_ROOT"

# create a simple index.html file for the default site
echo "<!DOCTYPE html>
<html>
<head>
    <title>Welcome to Nginx!</title>
    <style>
        body {
            width: 35em;
            margin: 0 auto;
            font-family: Tahoma, Verdana, Arial, sans-serif;
            padding-top: 50px;
            text-align: center;
        }
        h1 {
            color: #333;
        }
        p {
            color: #666;
        }
    </style>
</head>
<body>
    <h1>Success!</h1>
    <p>Your Nginx server on VPS is up and running.</p>
    <p>This is the default page for <strong>$DEFAULT_DOMAIN</strong>.</p>
</body>
</html>" | sudo tee "$DEFAULT_SITE_ROOT/index.html" > /dev/null

echo "Default website directory created at $DEFAULT_SITE_ROOT with index.html."

# create a default nginx server block configuration
echo -e "\n--- Creating default Nginx server block ---"
DEFAULT_NGINX_CONF="/etc/nginx/sites-available/$DEFAULT_DOMAIN"

# remove default Nginx config if it exists
if [ -f "/etc/nginx/sites-available/default" ]; then
    echo "Removing default Nginx configuration..."
    sudo rm /etc/nginx/sites-available/default
    sudo rm /etc/nginx/sites-enabled/default
fi

# create new config file
sudo bash -c "cat > $DEFAULT_NGINX_CONF <<EOF
server {
    listen 80;
    listen [::]:80;

    root $DEFAULT_SITE_ROOT;
    index index.html index.htm index.nginx-debian.html;

    server_name $DEFAULT_DOMAIN www.$DEFAULT_DOMAIN; # Replace with your actual domain

    location / {
        try_files \$uri \$uri/ =404;
    }

    # Optional: SSL configuration will go here later with Certbot
    # listen 443 ssl http2;
    # listen [::]:443 ssl http2;
    # ssl_certificate /etc/letsencrypt/live/$DEFAULT_DOMAIN/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/$DEFAULT_DOMAIN/privkey.pem;
    # include /etc/letsencrypt/options-ssl-nginx.conf;
    # ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}
EOF"

echo "Default Nginx configuration created at $DEFAULT_NGINX_CONF."

# enable and start Nginx service
echo -e "\n--- Enabling and starting Nginx service ---"
sudo ln -s "$DEFAULT_NGINX_CONF" "/etc/nginx/sites-enabled/$DEFAULT_DOMAIN"

# test Nginx configuration for syntax errors
echo "Testing Nginx configuration..."
sudo nginx -t

if [ $? -ne 0 ]; then
    echo "Error: Nginx configuration test failed. Please check the config file."
    exit 1
fi

sudo systemctl restart nginx
sudo systemctl enable nginx

echo "Nginx service enabled and restarted."

echo -e "\n--- Setup complete! ---"
echo "You should now be able to access your Nginx server by navigating to your VPS IP address or '$DEFAULT_DOMAIN' (after DNS configuration)."
echo "Remember to replace '$DEFAULT_DOMAIN' with your actual domain name and configure DNS records."

echo -e "\n--- Next Steps for adding more websites: ---"
echo "1. Create a new directory for your website: \`sudo mkdir -p /var/www/your_new_domain.com/html\`"
echo "2. Create an Nginx server block configuration: \`sudo nano /etc/nginx/sites-available/your_new_domain.com\`"
echo "   Example content for 'your_new_domain.com':"
echo "   \`\`\`nginx"
echo "   server {"
echo "       listen 80;"
echo "       listen [::]:80;"
echo "       root /var/www/your_new_domain.com/html;"
echo "       index index.html;"
echo "       server_name your_new_domain.com www.your_new_domain.com;"
echo "       location / {"
echo "           try_files \$uri \$uri/ =404;"
echo "       }"
echo "   }"
echo "   \`\`\`"
echo "3. Create a symbolic link to enable the site: \`sudo ln -s /etc/nginx/sites-available/your_new_domain.com /etc/nginx/sites-enabled/\`"
echo "4. Test Nginx configuration: \`sudo nginx -t\`"
echo "5. Restart Nginx: \`sudo systemctl restart nginx\`"
echo "6. Don't forget to configure your domain's DNS A/AAAA records to point to your VPS IP address!"
