# Despliegue de Infraestructura con Vagrant y OwnCloud

## 1. Índice

1. [Introducción](#introducción)
2. [Infraestructura y Direccionamiento IP](#infraestructura-y-direccionamiento-ip)
3. [Instalación y Configuración Paso a Paso](#instalación-y-configuración-paso-a-paso)
    - [Configuración del Vagrantfile](#configuración-del-vagrantfile)
    - [Configuración del Balanceador](#configuración-del-balanceador)
    - [Configuración del Servidor NFS](#configuración-del-servidor-nfs)
    - [Configuración de los Servidores Web](#configuración-de-los-servidores-web)
    - [Configuración del Servidor de Base de Datos](#configuración-del-servidor-de-base-de-datos)
4. [Scripts de Configuración](#scripts-de-configuración)
    - [4.1 Configuración de NGINX para Balanceo de Carga](#41-configuración-de-nginx-para-balanceo-de-carga)
    - [4.2 Configuración del Servidor NFS](#42-configuración-del-servidor-nfs)
    - [4.3 Configuración de los Servidores Backend con NGINX y Clientes NFS](#43-configuración-de-los-servidores-backend-con-nginx-y-clientes-nfs)
    - [4.4 Configuración del Servidor de Base de Datos](#44-configuración-del-servidor-de-base-de-datos)
---

## 2. Introducción

En este proyecto se despliega una infraestructura multi-capa utilizando **Vagrant** y **VirtualBox** para la implementación de **OwnCloud**. El despliegue incluye balanceo de carga, almacenamiento compartido mediante NFS, dos servidores web con PHP-FPM y un servidor de base de datos MariaDB.

### Infraestructura y Direccionamiento IP

La infraestructura se organiza en tres capas con las siguientes direcciones IP:

| Máquina               | Nombre           | Red1 (Privada) | Red2 (Privada) | Descripción                |
|-----------------------|------------------|---------------|---------------|----------------------------|
| Balanceador           | balanceadorJosein| 192.168.10.10 | -             | Servidor NGINX (Balanceo)  |
| Servidor NFS          | serverNFSJosein  | 192.168.10.20 | 192.168.20.50 | Almacenamiento compartido  |
| Servidor Web 1        | serverweb1Josein | 192.168.10.30 | 192.168.20.30 | Servidor Web OwnCloud      |
| Servidor Web 2        | serverweb2Josein | 192.168.10.31 | 192.168.20.31 | Servidor Web OwnCloud      |
| Servidor Base de Datos| serverdatosJosein| -             | 192.168.20.40 | Servidor MariaDB           |

---

## 3. Instalación y Configuración Paso a Paso

### 3.1 Configuración del Vagrantfile

El **Vagrantfile** define toda la infraestructura. A continuación, se muestra el código:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "debian/bullseye64"

  config.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 2
  end

  # Capa 1: Balanceador
  config.vm.define "balanceadorJosein" do |app|
    app.vm.hostname = "balanceadorJosein"
    app.vm.network "public_network"
    app.vm.network "private_network", ip: "192.168.10.10", virtualbox__intnet: "red1"
    app.vm.network "forwarded_port", guest: 80, host: 8080
  end

  # Capa 2: Servidores Web y NFS
  config.vm.define "serverNFSJosein" do |app|
    app.vm.network "private_network", ip: "192.168.10.20", virtualbox__intnet: "red1"
    app.vm.network "private_network", ip: "192.168.20.50", virtualbox__intnet: "red2"
  end
  config.vm.define "serverweb1Josein" do |app|
    app.vm.network "private_network", ip: "192.168.10.30", virtualbox__intnet: "red1"
  end
  config.vm.define "serverdatosJosein" do |app|
    app.vm.network "private_network", ip: "192.168.20.40", virtualbox__intnet: "red2"
  end
  config.ssh.insert_key = false
  config.ssh.forward_agent = false
end
```
## 4. Scripts

### 4.1 Configuración de NGINX para balanceo de carga

En este script instalo NGINX y lo configuro como un balanceador de carga. Defino dos servidores backend con las IPs 192.168.10.30 y 192.168.10.31 para repartir las 
solicitudes entre ellos. La configuración hace que NGINX escuche en el puerto 80 y redirija el tráfico hacia los servidores backend usando proxy_pass. Finalmente, reinicio 
NGINX para aplicar los cambios y dejarlo listo para funcionar como balanceador.

```ruby
# Actualizo la lista de paquetes disponibles
sudo apt-get update -y

# Instalo NGINX para usarlo como servidor web y proxy inverso
sudo apt-get install -y nginx

# Configuro el archivo de NGINX para usar balanceo de carga con dos servidores backend
cat <<EOF > /etc/nginx/sites-available/default
upstream backend_servers {
    server 192.168.10.30;  # Primer servidor backend
    server 192.168.10.31;  # Segundo servidor backend
}

server {
    listen 80;  # NGINX escucha en el puerto 80 (HTTP)
    location / {
        # Configuro los encabezados para que el cliente y servidor se comuniquen bien
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        
        # Hago que las solicitudes se redirijan a los servidores backend
        proxy_pass http://backend_servers;
    }
}
EOF

# Reinicio NGINX para aplicar los cambios de configuración
sudo systemctl restart nginx
```

### 4.2 Configuración del Servidor NFS

En este script configuro el servidor NFS y preparo el almacenamiento compartido para OwnCloud. Primero, instalo NFS y los módulos de PHP 7.4 necesarios. Luego, creo la carpeta compartida, ajusto sus permisos 
y la configuro para ser accesible desde los servidores backend. Descargo y descomprimo OwnCloud en esta carpeta, configuro un archivo automático para conectarlo con la base de datos, y ajusto PHP-FPM para que 
escuche en la IP del servidor NFS. Por último, aplico los cambios reiniciando los servicios y realizo una pequeña modificación en el estilo de OwnCloud como ejemplo. Esto deja listo el servidor NFS con OwnCloud 
configurado.

```ruby
# Actualizo la lista de paquetes disponibles
sudo apt-get update -y

# Instalo NFS, PHP 7.4 y los módulos necesarios para OwnCloud
sudo apt-get install -y nfs-kernel-server php7.4 php7.4-fpm php7.4-mysql php7.4-gd php7.4-xml php7.4-mbstring php7.4-curl php7.4-zip php7.4-intl php7.4-ldap unzip curl

# Creo la carpeta compartida para OwnCloud y configuro los permisos
mkdir -p /var/nfs/general
sudo chown -R www-data:www-data /var/nfs/general  # Cambio el propietario a www-data
sudo chmod -R 755 /var/nfs/general               # Permisos de lectura, escritura y ejecución adecuados

# Configuro NFS para compartir la carpeta con los servidores backend
sudo echo "/var/nfs/general 192.168.10.30(rw,sync,no_subtree_check)" >> /etc/exports
sudo echo "/var/nfs/general 192.168.10.31(rw,sync,no_subtree_check)" >> /etc/exports

# Aplico los cambios en NFS y reinicio el servicio
sudo exportfs -a
sudo systemctl restart nfs-kernel-server

# Descargo y descomprimo OwnCloud en la carpeta compartida
cd /tmp
sudo wget https://download.owncloud.com/server/stable/owncloud-10.9.1.zip
sudo unzip owncloud-10.9.1.zip
sudo mv owncloud /var/nfs/general/

# Configuro permisos correctos para OwnCloud
sudo chown -R www-data:www-data /var/nfs/general/owncloud  # Asigno propietario
sudo chmod -R 755 /var/nfs/general/owncloud               # Permisos adecuados

# Creo un archivo de configuración automática para OwnCloud
cat <<EOF > /var/nfs/general/owncloud/config/autoconfig.php
<?php
\$AUTOCONFIG = array(
  "dbtype" => "mysql",
  "dbname" => "owncloud_db",
  "dbuser" => "owncloud_user",
  "dbpassword" => "2024",
  "dbhost" => "192.168.20.40",
  "directory" => "/var/nfs/general/owncloud/data",
  "adminlogin" => "admin",
  "adminpass" => "2024"
);
EOF

# Configuro PHP-FPM para que escuche en la IP del servidor NFS en el puerto 9000
sudo sed -i 's/^listen = .*/listen = 192.168.10.20:9000/' /etc/php/7.4/fpm/pool.d/www.conf

# Modifico el estilo de OwnCloud cambiando el color de fondo (ejemplo simple)
sudo sed -i 's/background-color: .*/background-color: #ff0000;/' /var/nfs/general/owncloud/core/css/styles.css

# Reinicio PHP-FPM para aplicar los cambios
sudo systemctl restart php7.4-fpm

# Elimino la ruta por defecto del sistema
sudo ip route del default
```

### 4.3 Configuración de los Servidores Backen con Nginx y clientes del Servidor NFS

En este script configuro un servidor web para que funcione con OwnCloud utilizando NGINX y la carpeta compartida por NFS. Primero, instalo NGINX, herramientas de NFS y los módulos de PHP 7.4 necesarios. 
Luego, monto la carpeta compartida desde el servidor NFS en la ruta local y configuro su montaje de forma persistente en el archivo /etc/fstab. Después, edito la configuración de NGINX para servir los 
archivos de OwnCloud desde la carpeta compartida y para procesar archivos PHP mediante PHP-FPM. Por último, reinicio los servicios de NGINX y PHP-FPM para aplicar los cambios. Esto deja el servidor web 
listo para manejar solicitudes hacia OwnCloud.

```ruby

# Actualizo la lista de paquetes disponibles
sudo apt-get update -y

# Instalo NGINX, herramientas NFS y módulos de PHP necesarios para OwnCloud
sudo apt-get install -y nginx nfs-common php7.4 php7.4-fpm php7.4-mysql php7.4-gd php7.4-xml php7.4-mbstring php7.4-curl php7.4-zip php7.4-intl php7.4-ldap mariadb-client

# Creo un directorio local donde se montará la carpeta compartida por NFS
sudo mkdir -p /var/nfs/general

# Monta la carpeta compartida desde el servidor NFS en la ruta local
sudo mount -t nfs 192.168.10.20:/var/nfs/general /var/nfs/general

# Agrego la configuración de montaje NFS al /etc/fstab para que sea persistente después de reiniciar
sudo echo "192.168.10.20:/var/nfs/general    /var/nfs/general   nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0" | sudo tee -a /etc/fstab

# Configuro NGINX para servir los archivos de OwnCloud desde la carpeta compartida
cat <<EOF > /etc/nginx/sites-available/default
server {
    listen 80;  # NGINX escuchará en el puerto 80

    root /var/nfs/general/owncloud;
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
```

### 4.4 Configuración del Servidor con la base de datos

En este script configuro el servidor de base de datos utilizando MariaDB para soportar OwnCloud. Primero, instalo MariaDB y edito su configuración para permitir conexiones remotas, 
estableciendo la dirección IP del servidor (192.168.20.40) como punto de escucha. Luego, reinicio el servicio para aplicar estos cambios. A continuación, creo la base de datos owncloud_db y un 
usuario llamado owncloud_user con todos los permisos necesarios para que OwnCloud pueda interactuar con la base de datos. Por último, elimino la ruta predeterminada como parte de la configuración de 
red. Esto deja el servidor de base de datos listo para ser utilizado por OwnCloud.


```ruby
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
```



