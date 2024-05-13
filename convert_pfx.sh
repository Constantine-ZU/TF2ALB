#!/bin/bash

# The path to the directory given as the first argument to the script, or the current directory if no argument is given
directory=${1:-$(pwd)}

# Loop through all .pfx files in the specified directory
find "$directory" -type f -name "*.pfx" | while read -r pfx_file; do
  # file name without extension
  base_name="${pfx_file%.*}"

# Commands to create .crt and .key files from .pfx
   # Replace 'yourpassword' with your password if .pfx files are password protected
openssl pkcs12 -in "$pfx_file" -clcerts -nokeys -out "${base_name}.crt" -passin pass:
  openssl pkcs12 -in "$pfx_file" -nocerts -nodes -out "${base_name}.key" -passin pass:


  echo "creating: ${base_name}.crt и ${base_name}.key"
done
