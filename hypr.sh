#!/bin/bash

# Verificar si el script se ejecuta con privilegios de superusuario
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script debe ejecutarse como superusuario. Usa 'sudo' para ejecutarlo."
    exit 1
fi

# Ruta del archivo de log
LOG_FILE="/var/log/instalar_hyprland.log"

# Función para registrar en el log
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

log_message "Iniciando instalación y configuración de Hyprland..."

# Confirmar con el usuario antes de proceder
read -p "¿Estás seguro de que deseas continuar con la instalación de Hyprland? (s/n): " confirm
if [[ ! $confirm =~ ^[Ss]$ ]]; then
    echo "Instalación cancelada."
    exit 0
fi

# Crear archivo de configuración de Hyprland
log_message "Creando archivo de configuración /etc/xbps.d/hyprland-void.conf"
echo "repository=https://raw.githubusercontent.com/Makrennel/hyprland-void/repository-x86_64-musl" | sudo tee /etc/xbps.d/hyprland-void.conf > /dev/null

# Verificar si los paquetes están instalados, solo instalar si es necesario
PACKAGES=("hyprland" "git" "xdg-desktop-portal-hyprland" "hyprland-protocols" "seatd" "polkit" "elogind" "dbus" "mesa-dri")
for PACKAGE in "${PACKAGES[@]}"; do
    if ! xbps-query -Rs $PACKAGE > /dev/null; then
        log_message "Instalando $PACKAGE..."
        sudo xbps-install -y $PACKAGE
    else
        log_message "$PACKAGE ya está instalado."
    fi
done

# Crear enlaces simbólicos para los servicios
log_message "Habilitando servicios necesarios"
sudo ln -s /etc/sv/dbus /var/service
sudo ln -s /etc/sv/polkitd /var/service
sudo ln -s /etc/sv/seatd /var/service

# Añadir el usuario al grupo _seatd
log_message "Añadiendo el usuario calamarino al grupo _seatd"
sudo usermod -aG _seatd calamarino

# Copiar el archivo hyprland.conf desde la misma carpeta del script a ~/.config/hypr/
log_message "Copiando archivo de configuración hyprland.conf a ~/.config/hypr/"
cp "$(dirname "$0")/hyprland.conf" /home/calamarino/.config/hypr/hyprland.conf
chown calamarino:calamarino /home/calamarino/.config/hypr/hyprland.conf

# Detectar la mejor resolución de la pantalla automáticamente
log_message "Detectando la mejor resolución disponible..."
BEST_RESOLUTION=$(xrandr | grep '*' | sort -nr | head -n 1 | awk '{print $1}')

log_message "Mejor resolución detectada: $BEST_RESOLUTION"

# Actualizar la configuración de Hyprland para usar la mejor resolución
log_message "Actualizando archivo de configuración de Hyprland con la mejor resolución."
sed -i "s/^monitor=.*/monitor=LVDS-1,$BEST_RESOLUTION,0x0/" /home/calamarino/.config/hypr/hyprland.conf

# Instalar fuentes necesarias
log_message "Instalando fuentes necesarias..."
sudo xbps-install -y fontconfig ttf-dejavu ttf-liberation

# Mover imagen wallpaper.jpg a /home/calamarino/Pictures/ y renombrarla a background.jpg
log_message "Moviendo wallpaper.jpg a /home/calamarino/Pictures/ y renombrando a background.jpg"
mv "$(dirname "$0")/wallpaper.jpg" /home/calamarino/Pictures/background.jpg
chown calamarino:calamarino /home/calamarino/Pictures/background.jpg

log_message "Instalación y configuración completada."

# Sugerir reinicio
echo "¡Reinicia el sistema para aplicar todos los cambios!"

# Fin
