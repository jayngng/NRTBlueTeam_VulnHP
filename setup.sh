# Update machine
sudo apt-get -y update

# Install and configure FTP service
sudo apt install -y vsftpd
sudo systemctl start vsftpd
sudo systemctl enable vsftpd
sudo ufw allow 20/tcp
sudo ufw allow 21/tcp

# Allow FTP anonymous login
sudo cp new_vsftpd.conf /etc/vsftpd.conf
sudo mkdir -p /var/ftp/pub
sudo chown www-data:www-data /var/ftp/pub
sudo chmod 777 /var/ftp/pub
echo "/var/ftp/pub/pubf.txt" | sudo tee /var/ftp/pub/pubf.txt
sudo systemctl restart vsftpd

# Set up HTTP service.
sudo apt-get install -y apache2
sudo apt-get install -y libapache2-mod-php
sudo a2dismod mpm_event && sudo a2enmod mpm_prefork && sudo a2enmod php7.2
sudo ufw allow 'Apache'
sudo cp apache2.conf /etc/apache2/apache2.conf

# Set up LFI vulnerability
sudo cp 000-default.conf /etc/apache2/sites-available/000-default.conf
sudo cp -r development/ /var/www/html/
sudo cp -r main_site/* /var/www/html/
sudo systemctl restart apache2.service

# Install Fail2Ban
sudo apt-get install -y fail2ban
sudo service fail2ban start

# Privilege Escalation
sudo chmod +s /usr/bin/find

# Set up log parser
sudo cp logparse /usr/bin/
