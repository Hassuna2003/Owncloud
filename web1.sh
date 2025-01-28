# Actualizo la lista de paquetes disponibles
sudo apt-get update -y

# Instalo NGINX, herramientas NFS y módulos de PHP necesarios para OwnCloud
sudo apt-get install -y nginx nfs-common php7.4 php7.4-fpm php7.4-mysql php7.4-gd php7.4-xml php7.4-mbstring php7.4-curl php7.4-zip php7.4-intl php7.4-ldap mariadb-client

# Creo un directorio local donde se montará la carpeta compartida por NFS
sudo mkdir -p /var/www/html

# Monta la carpeta compartida desde el servidor NFS en la ruta local
sudo mount -t nfs 192.168.10.20:/var/www/html /var/www/html

# Agrego la configuración de montaje NFS al /etc/fstab para que sea persistente después de reiniciar
sudo echo "192.168.10.20:/var/www/html    /var/www/html   nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0" | sudo tee -a /etc/fstab

# Configuro NGINX para servir los archivos de OwnCloud desde la carpeta compartida
cat <<EOF > /etc/nginx/sites-available/default
server {
    listen 80;  # NGINX escuchará en el puerto 80

    root /var/www/html/owncloud;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;  # Redirigir solicitudes a index.php si no se encuentra el archivo
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;   # Configuraciones básicas de FastCGI
        fastcgi_pass 192.168.10.20:9000;     # PHP-FPM escuchando en el servidor NFS
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;              # Parámetros adicionales de FastCGI
    }

    location ~ ^/(?:\.htaccess|data|config|db_structure\.xml|README) {
        deny all;
    }
}
EOF

# Reinicio NGINX para que aplique la nueva configuración
sudo systemctl restart nginx

# Reinicio PHP-FPM
sudo systemctl restart php7.4-fpm

# Elimino la ruta predeterminada
sudo ip route del default
