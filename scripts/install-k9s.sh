#!/usr/bin/env bash
echo "installing k9s ..."
VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -Lo k9s.tar.gz "https://github.com/derailed/k9s/releases/download/${VERSION}/k9s_Linux_amd64.tar.gz"
tar -xzf k9s.tar.gz k9s
sudo mv k9s /usr/local/bin/
rm k9s.tar.gz
