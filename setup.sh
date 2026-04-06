#!/bin/bash

echo "[+] Fluffy Paws Lab setup started..."

if [ "$EUID" -ne 0 ]; then
echo "[!] Please run as root: sudo bash setup.sh"
exit 1
fi

DOMAIN="lab.local"
WEB_ROOT="/var/www/html"
TARGET_PATH="$WEB_ROOT/file-upload-rce-lab"
CURRENT_PATH="$(pwd)"

echo "[+] Installing dependencies..."
apt update -y
apt install apache2 php libapache2-mod-php -y

echo "[+] Deploying lab..."

rm -rf $TARGET_PATH
mkdir -p $TARGET_PATH

cp -r $CURRENT_PATH/app/* $TARGET_PATH

echo "[+] App deployed to $TARGET_PATH"

echo "[+] Creating user 'dev'..."
if id "dev" &>/dev/null; then
echo "[*] User exists"
else
useradd -m -s /bin/bash dev
echo "dev:SuperSecret123" | chpasswd
fi

echo "[+] Configuring sudo misconfiguration..."
echo "dev ALL=(ALL) NOPASSWD: /usr/bin/find" > /etc/sudoers.d/dev
chmod 440 /etc/sudoers.d/dev

echo "[+] Setting permissions..."
chown -R www-data:www-data $TARGET_PATH
chmod -R 755 $TARGET_PATH
chmod 777 $TARGET_PATH/uploads

echo "[+] Enabling .htaccess..."
sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf

echo "[+] Creating VirtualHost..."
cat > /etc/apache2/sites-available/lab.conf <<EOL
<VirtualHost *:80>
ServerName $DOMAIN
DocumentRoot $TARGET_PATH

```
<Directory $TARGET_PATH>
    AllowOverride All
    Require all granted
</Directory>
```

</VirtualHost>
EOL

a2ensite lab.conf
a2dissite 000-default.conf

echo "[+] Updating /etc/hosts..."
if ! grep -q "$DOMAIN" /etc/hosts; then
echo "127.0.0.1 $DOMAIN" >> /etc/hosts
fi

systemctl restart apache2

echo ""
echo "[+] Lab ready:"
echo "http://$DOMAIN"
echo ""
echo "[+] Credentials:"
echo "dev / SuperSecret123"

