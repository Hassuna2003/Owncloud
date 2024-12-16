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
