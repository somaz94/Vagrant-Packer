#!/usr/bin/env bash
###### account security settings
# 0. backup
#sudo cp /etc/pam.d/system-auth{,.orig}
#sudo cp /etc/pam.d/password-auth{,.orig}
#sudo authconfig --savebackup=authconfig_backup

# 1. password '2 factor 10 length' or '3 factor 8 length'

# at least one lower case letter
#sudo authconfig --enablereqlower --update

# at least one upper case letter
#sudo authconfig --enablerequpper --update

# at least one number
#sudo authconfig --enablereqdigit --update

# password over 8 length
sudo sed -i 's#PASS_MIN_LEN\t5#PASS_MIN_LEN\t8#g' /etc/login.defs

# 2. [U-47] password max 90 days
sudo sed -i 's#PASS_MAX_DAYS\t99999#PASS_MAX_DAYS\t90#g'  /etc/login.defs
#sudo chage -M 90 clex
#sudo chage -M 90 root

# 3. [U-48] password min 7 days
sudo sed -i 's#PASS_MIN_DAYS\t0#PASS_MIN_DAYS\t7#g'   /etc/login.defs
#sudo chage -m 7 clex
#sudo chage -m 7 root

# 4. remember last 12 passwords
sudo sed -i '/password    sufficient/ !b; s/$/ remember=12/' /etc/pam.d/system-auth

# 5. password-auth
sudo sed -i '5iauth        required      pam_tally2.so file=/var/log/tallylog deny=5 unlock_time=1800' /etc/pam.d/password-auth
sudo sed -i '15iaccount     required      pam_tally2.so' /etc/pam.d/password-auth

# 6. move tallylog
#sudo mv /var/log/tallylog{,.bak}

# 7. [U-03] system-auth
sudo sed -i '5iauth        required      pam_tally2.so file=/var/log/tallylog deny=5 unlo ck_time=1800 no_magic_root' /etc/pam.d/system-auth
sudo sed -i '15iaccount        required      pam_tally2.so no_magic_root reset' /etc/pam.d/system-auth

# 8. [U-45] su
sudo sed -i '5iauth           required        pam_wheel.so use_uid' /etc/pam.d/su
sudo chgrp wheel /bin/su
sudo chmod 4750 /bin/su

##### [U-13] suid, guid, sticky bit permission
sudo chmod u-s /usr/bin/newgrp
sudo chmod u-s /sbin/unix_chkpwd

##### [U-69] login warning message banner
cat << EOF |sudo tee /etc/motd
##########################################################
#                                                        #
#                      Warning!!                         #
#        This system is for authrized users only!!       #
#                                                        #
##########################################################
EOF

cat << EOF |sudo tee /etc/issue.net
##########################################################
#                                                        #
#                      Warning!!                         #
#        This system is for authrized users only!!       #
#                                                        #
##########################################################
EOF

cat << EOF |sudo tee /etc/banner
##########################################################
#                                                        #
#                      Warning!!                         #
#        This system is for authrized users only!!       #
#                                                        #
##########################################################
EOF

sudo sed -i '1iBanner /etc/banner' /etc/ssh/sshd_config

##### [U-18] TCPwrapper hosts.deny all deny
#cat << EOF |sudo tee /etc/hosts.deny
#ALL:ALL
#EOF

