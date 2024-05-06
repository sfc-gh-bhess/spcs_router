#!/bin/bash

# Prompt user for input
read -p "What is the image repository URL (SHOW IMAGE REPOSITORIES IN SCHEMA)? " repository_url

# Paths to the files
makefile="./Makefile"
router_yaml="./router.yaml"

# Copy files
cp $makefile.template $makefile
cp $router_yaml.template $router_yaml

# Replace placeholders in Makefile file using | as delimiter
sed -i "" "s|<<REPOSITORY>>|$repository_url|g" $makefile

# Replace placeholders in SPCS YAML file using | as delimiter
sed -i "" "s|<<REPOSITORY>>|$repository_url|g" $router_yaml

echo "Placeholder values have been replaced!"
echo "Run 'make help' to view the targets."
