#!/bin/bash


S3_PATH=${S3_PATH:-"s3://constantine-z-2/"}
PFX_FILE_NAME=${PFX_FILE_NAME:-"webaws_pam4_com_2024_05_13.pfx"}
APP_NAME=${APP_NAME:-"BlazorAut"}
S3_BASE_URL="https://constantine-z.s3.eu-north-1.amazonaws.com"


echo "Using S3_PATH: $S3_PATH"
echo "Using PFX_FILE_NAME: $PFX_FILE_NAME"
echo "Using APP_NAME: $APP_NAME"
echo "Using S3_BASE_URL: $S3_BASE_URL"


sudo apt-get update
sudo apt-get install -y postgresql-client
sudo snap install aws-cli --classic


aws s3 cp ${S3_PATH}${PFX_FILE_NAME} ./${PFX_FILE_NAME}
sudo mv ./${PFX_FILE_NAME} /etc/ssl/certs/${APP_NAME}.pfx
sudo chmod 600 /etc/ssl/certs/${APP_NAME}.pfx


sudo mkdir -p /var/www/${APP_NAME}
curl -L -o ${APP_NAME}.tar ${S3_BASE_URL}/${APP_NAME}.tar
sudo tar -xf ${APP_NAME}.tar -C /var/www/${APP_NAME}
sudo chmod +x /var/www/${APP_NAME}/${APP_NAME}
sudo chmod -R 755 /var/www/${APP_NAME}/wwwroot/

echo "[Unit]
Description=${APP_NAME} Web App

[Service]
WorkingDirectory=/var/www/${APP_NAME}
ExecStart=/var/www/${APP_NAME}/${APP_NAME}
Restart=always
RestartSec=10
SyslogIdentifier=${APP_NAME}

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/${APP_NAME}.service


sudo systemctl daemon-reload
sudo systemctl enable ${APP_NAME}
sudo systemctl start ${APP_NAME}
