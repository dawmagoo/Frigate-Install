#!/bin/bash

# Sprawdź, czy skrypt jest uruchamiany jako root
if [[ $EUID -ne 0 ]]; then
   echo "Ten skrypt musi być uruchomiony jako root" 
   exit 1
fi

echo "=== Instalacja Docker ==="
# Aktualizacja systemu i instalacja Docker
apt update && apt install -y docker.io

# Uruchom Docker i ustaw go do automatycznego uruchamiania przy starcie
systemctl start docker
systemctl enable docker

echo "=== Instalacja Docker Compose ==="
# Instalacja Docker Compose
apt install -y docker-compose

# Tworzenie struktury katalogów dla Frigate
echo "=== Tworzenie katalogów dla Frigate ==="
mkdir -p /opt/frigate/config
mkdir -p /opt/frigate/media/clips
mkdir -p /opt/frigate/media/recordings

# Tworzenie pliku konfiguracyjnego dla Frigate
echo "=== Tworzenie pliku konfiguracyjnego config.yml ==="
cat <<EOL > /opt/frigate/config/config.yml
detectors:
  cpu1:
    type: cpu

cameras:
  kamera_1:
    ffmpeg:
      inputs:
        - path: rtsp://user:password@adres_ip_kamery:554/ścieżka_strumienia
          roles:
            - detect
            - rtmp
    width: 1920
    height: 1080
    fps: 5
EOL

# Tworzenie pliku docker-compose.yml dla Frigate
echo "=== Tworzenie pliku docker-compose.yml ==="
cat <<EOL > /opt/frigate/docker-compose.yml
version: "3.9"
services:
  frigate:
    container_name: frigate
    image: blakeblackshear/frigate:stable
    privileged: true
    restart: unless-stopped
    shm_size: "64mb"
    volumes:
      - /dev/bus/usb:/dev/bus/usb
      - /etc/localtime:/etc/localtime:ro
      - ./config/config.yml:/config/config.yml:ro
      - ./media/clips:/media/frigate/clips
      - ./media/recordings:/media/frigate/recordings
      - type: tmpfs
        target: /tmp/cache
        tmpfs:
          size: 1000000000
    ports:
      - "5000:5000"
      - "1935:1935"
    environment:
      - FRIGATE_RTSP_PASSWORD=twoje_haslo_do_rtsp
EOL

# Ustawienie uprawnień do katalogów
echo "=== Ustawianie uprawnień do katalogów ==="
chown -R $USER:$USER /opt/frigate

# Przechodzenie do katalogu i uruchomienie kontenera Frigate
echo "=== Uruchamianie Frigate ==="
cd /opt/frigate
docker-compose up -d

# Wyświetlenie podsumowania
echo
echo "=== Instalacja zakończona! ==="
echo "Frigate jest dostępny pod adresem: http://localhost:5000"
echo "Jeśli używasz tego serwera zdalnie, zamień 'localhost' na adres IP serwera."
echo
echo "Skonfiguruj kamery edytując plik: /opt/frigate/config/config.yml"
echo "Aby przeładować konfigurację po modyfikacjach, uruchom ponownie Frigate:"
echo "  cd /opt/frigate && docker-compose restart"
echo
echo "=== Dziękujemy za użycie skryptu! ==="
