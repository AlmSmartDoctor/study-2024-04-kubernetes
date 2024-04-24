#!/bin/bash

echo "alias k='kubectl'" >> ~/.zshrc
echo "alias ka='kubectl get all --all-namespaces'" >> ~/.zshrc
echo '[[ $commands[kubectl] ]] && source <(kubectl completion zsh)' >> ~/.zshrc