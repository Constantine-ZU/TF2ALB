#!/bin/bash

DB_HOST=${DB_HOST:-"pgaws.pam4.com"}
DB_USER=${DB_USER:-"dbuser"}
DB_PASS=${DB_PASS:-"password"}
DB_NAME=${DB_NAME:-"dbwebaws"}
S3_BUCKET=${S3_BUCKET:-"s3://constantine-z-2/"}


DUMP_FILE_PATH="${S3_BUCKET}${DB_NAME}_backup.dump"

echo "!-apt-get update"
sudo apt-get update
sudo apt-get install -y postgresql-client

echo "!- Setup AWS-cli"
sudo snap install aws-cli --classic

echo "!-Downloading database dump from S3..."
aws s3 cp ${DUMP_FILE_PATH} ~/dbwebaws_backup.dump


# echo "!-Waiting for the PostgreSQL database to become ready..."
# max_attempts=50
# attempt_no=0
echo "!-Pg_Dump arguments Length of DB_PASS: ${#DB_PASS}, First three characters: ${DB_PASS:0:3}"
#PGPASSWORD=$DB_PASS

echo "!-Restoring database from dump..."
PGPASSWORD=$DB_PASS pg_restore -h $DB_HOST -U $DB_USER -d $DB_NAME -v ~/dbwebaws_backup.dump || echo "Failed to restore database"


echo "1-Database restoration complete."
