#!/usr/bin/env bash

apt-get update
apt-get install -y apache2
if ! [ -L /var/www ]; then
    rm -rf /var/www
    ln -fs /vagrant_shared /var/www
fi

echo "<html><head><title>hello world</title></head><body><h2>hello world</h2>things are working, at least up to this point</body></html>" > /vagrant_shared/hello_world.html
