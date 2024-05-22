
#!/bin/bash


S3_PATH=${S3_PATH:-"s3://constantine-z-2/"}
PFX_FILE_NAME=${PFX_FILE_NAME:-"webaws_pam4_com_2024_05_13.pfx"}
APP_NAME=${APP_NAME:-"BlazorAut"}
S3_BASE_URL="https://constantine-z.s3.eu-north-1.amazonaws.com"
DB_HOST=${DB_HOST:-"pgaws.pam4.com"}
DB_USER=${DB_USER:-"dbuser"}
DB_PASS=${DB_PASS:-"XXX"}

echo "Using S3_PATH: $S3_PATH"
echo "Using PFX_FILE_NAME: $PFX_FILE_NAME"
echo "Using APP_NAME: $APP_NAME"
echo "Using S3_BASE_URL: $S3_BASE_URL"


sudo apt-get update
sudo apt-get install -y postgresql-client
sudo snap install aws-cli --classic
sudo apt-get install -y jq #edit app settings


aws s3 cp ${S3_PATH}${PFX_FILE_NAME} ./${PFX_FILE_NAME}
sudo mv ./${PFX_FILE_NAME} /etc/ssl/certs/${APP_NAME}.pfx
sudo chmod 600 /etc/ssl/certs/${APP_NAME}.pfx


sudo mkdir -p /var/www/${APP_NAME}
curl -L -o ${APP_NAME}.tar ${S3_BASE_URL}/${APP_NAME}.tar
sudo tar -xf ${APP_NAME}.tar -C /var/www/${APP_NAME}
sudo chmod +x /var/www/${APP_NAME}/${APP_NAME}
sudo chmod -R 755 /var/www/${APP_NAME}/wwwroot/

#edit appsettings.json

APPSETTINGS_PATH="/var/www/${APP_NAME}/appsettings.json"

jq --arg db_host "$DB_HOST" \
   --arg db_user "$DB_USER" \
   --arg db_pass "$DB_PASS" \
   '.ConnectionStrings.DefaultConnection = ("Host=" + $db_host + ";Database=dbwebaws;Username=" + $db_user + ";Password=" + $db_pass)' \
   $APPSETTINGS_PATH > $APPSETTINGS_PATH.tmp && mv $APPSETTINGS_PATH.tmp $APPSETTINGS_PATH



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


