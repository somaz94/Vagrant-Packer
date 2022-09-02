#!/bin/sh
# ssh connect to clex
echo "sudo su - clex" >> .bashrc

# Clex User Create
adduser clex -u 1100 -G wheel -p $(echo 'cloud!234' | openssl passwd -1 -stdin)

# DNS nameserver insert
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

# config sshd
#Disable Message when using ssh 'Are you sure you want to continue connecting'
sudo sed -i '/StrictHostKeyChecking/a StrictHostKeyChecking no' /etc/ssh/ssh_config

# SSH UseDNS disable, disable root login
sudo sed -i '/UseDNS no/d' /etc/ssh/sshd_config
sudo sed -i '/#UseDNS/a UseDNS no' /etc/ssh/sshd_config

systemctl restart sshd

yum install -y tigervnc-server
mkdir -p /home/clex/.vnc
echo 'cloud!234' | vncpasswd clex -f > /home/clex/.vnc/passwd
chown clex.clex -R /home/clex/.vnc
chmod 0600 /home/clex/.vnc/passwd

cp /lib/systemd/system/vncserver@.service  /etc/systemd/system/vncserver@:10.service
sed -i s/\<USER\>/clex/ /etc/systemd/system/vncserver@\:10.service
systemctl daemon-reload
systemctl enable vncserver@:10
systemctl start vncserver@:10

# local small dns & vagrant cannot parse and delivery shell code.
for (( i=1; i<=$1; i++  )); do echo "192.168.20.1$i control0$i" >> /etc/hosts; done
for (( i=1; i<=$2; i++  )); do echo "192.168.20.10$i compute0$i" >> /etc/hosts; done
for (( i=1; i<=$3; i++  )); do echo "192.168.20.20$i ceph0$i" >> /etc/hosts; done
