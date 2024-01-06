#!/bin/bash

# Update ubuntu server
echo "####################### Update Server ################################"
sudo apt update

# Install docker
echo "####################### Install Docker ################################"
sudo apt install docker.io -y

# sudo docker network create jenkins
echo "####################### Creating network for Jenkins in Server ################################"
sudo docker network create jenkins

# Run the docker:dind
echo "####################### Running docker:dind ################################"
sudo docker run --name jenkins-docker --rm --detach \
  --privileged --network jenkins --network-alias docker \
  --env DOCKER_TLS_CERTDIR=/certs \
  --volume jenkins-docker-certs:/certs/client \
  --volume jenkins-data:/var/jenkins_home \
  --publish 2376:2376 \
  docker:dind --storage-driver overlay2

# Create a Dockerfile
echo "####################### Creating Dockerfile ################################"
echo "FROM jenkins/jenkins:2.426.1-jdk17" > Dockerfile
echo "USER root" >> Dockerfile
echo "RUN apt-get update && apt-get install -y lsb-release" >> Dockerfile
echo "RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \\" >> Dockerfile
echo "  https://download.docker.com/linux/debian/gpg" >> Dockerfile
echo "RUN echo \"deb [arch=\$(dpkg --print-architecture) \\" >> Dockerfile
echo "  signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \\" >> Dockerfile
echo "  https://download.docker.com/linux/debian \\" >> Dockerfile
echo "  \$(lsb_release -cs) stable\" > /etc/apt/sources.list.d/docker.list" >> Dockerfile
echo "RUN apt-get update && apt-get install -y docker-ce-cli" >> Dockerfile
echo "USER jenkins" >> Dockerfile
echo "RUN jenkins-plugin-cli --plugins \"blueocean docker-workflow\"" >> Dockerfile

echo "Dockerfile created successfully."

# Build myjenkins-blueocean:2.426.1–1 image
echo "####################### Building myjenkins-blueocean:2.426.1–1 image ################################"
sudo docker build -t myjenkins-blueocean:2.426.1-1 .

# Run myjenkins-blueocean:2.426.1-1 image as a container
echo "####################### Running myjenkins-blueocean:2.426.1-1 image as a container ################################"
sudo docker run --name jenkins-blueocean --restart=on-failure --detach \
  --network jenkins --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 \
  --publish 8080:8080 --publish 50000:50000 \
  --volume jenkins-data:/var/jenkins_home \
  --volume jenkins-docker-certs:/certs/client:ro \
  myjenkins-blueocean:2.426.1-1

# Display Password
echo "####################### Display Password ################################"
sudo docker exec jenkins-blueocean cat /var/jenkins_home/secrets/initialAdminPassword
