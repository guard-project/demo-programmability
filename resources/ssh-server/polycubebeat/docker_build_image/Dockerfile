# Dockerfile for Polycubebeat Image creation

# Download base image ubuntu 18.04
FROM ubuntu:18.04

# Update software repository
RUN apt-get update

RUN mkdir -p /root/config/

# Copy Polycubebeat (program and configuration) on the image
COPY polycubebeat /root/
COPY polycubebeat.yml /root/config/

RUN ln -fs /root/config/polycubebeat.yml /root/

# Copy start script on the image
COPY start.sh /root/start.sh

# Execute start script
# CMD ["/root/start.sh"]
ENTRYPOINT ["/root/start.sh"]
