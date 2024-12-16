# Actualizo la lista de paquetes disponibles
sudo apt-get update -y

# Instalo MariaDB Server para usarlo como base de datos
sudo apt-get install -y mariadb-server

# Configuro MariaDB para permitir conexiones remotas desde los servidores web
sudo sed -i 's/bind-address.*/bind-address = 192.168.20.40/' /etc/mysql/mariadb.conf.d/50-server.cnf

# Reinicio MariaDB para aplicar la nueva configuración
sudo systemctl restart mariadb

# Creo la base de datos y el usuario para OwnCloud
sudo mysql -u root <<EOF
CREATE DATABASE owncloud_db;
CREATE USER 'owncloud_user'@'%' IDENTIFIED BY '2024';
GRANT ALL PRIVILEGES ON owncloud_db.* TO 'owncloud_user'@'%';
FLUSH PRIVILEGES;
EOF

# Elimino la ruta predeterminada
sudo ip route del default
