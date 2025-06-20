#!/bin/bash
curl -sL https://get.helm.sh/helm-v3.17.3-linux-amd64.tar.gz | tar -xz --strip-components=1 linux-amd64/helm
sudo mv helm /usr/local/bin/
