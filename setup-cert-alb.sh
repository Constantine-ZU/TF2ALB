#!/bin/bash

# Обновление системы и установка необходимых инструментов
sudo apt-get update
sudo snap install aws-cli --classic
sudo apt-get install -y openssl

# Загрузка сертификата
aws s3 cp s3://constantine-z-2/20240808_43c3e236.pfx /etc/ssl/certs/20240808_43c3e236.pfx
sudo chmod 600 /etc/ssl/certs/20240808_43c3e236.pfx

# Конвертация сертификата
openssl pkcs12 -in /etc/ssl/certs/20240808_43c3e236.pfx -clcerts -nokeys -out /etc/ssl/certs/certificate.crt -password pass:YOUR_PASSWORD
openssl pkcs12 -in /etc/ssl/certs/20240808_43c3e236.pfx -nocerts -nodes -out /etc/ssl/certs/private.key -password pass:YOUR_PASSWORD

# Импорт сертификата в ACM
CERT_ARN=$(aws acm import-certificate --certificate fileb:///etc/ssl/certs/certificate.crt \
                                      --private-key fileb:///etc/ssl/certs/private.key \
                                      --region eu-north-1 \
                                      --query 'CertificateArn' --output text)

# Здесь добавьте команды для обновления ALB с новым ARN сертификата
