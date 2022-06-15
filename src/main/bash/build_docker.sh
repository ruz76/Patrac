sudo apt-get update
sudo apt install docker.io
sudo usermod -aG docker $USER
exit #need to login again - or we need to referesh prvivileges added in previous step

docker build -t ruz76-patrac-store .

