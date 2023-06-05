#!/bin/bash

# check if the user is root, if not ask for password
if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

# update and upgrade the system (apt)
echo "[*] update and upgrade the system (apt)"
apt update && apt upgrade -y

# install vsftpd
echo "[*] install vsftpd"
apt install vsftpd -y

# edit the /etc/vsftpd.conf file 

# uncomment #write_enable=YES
echo "[*] uncomment #write_enable=YES"
sed -i 's/#write_enable=YES/write_enable=YES/g' /etc/vsftpd.conf

# uncomment #chroot_local_user=YES
echo "[*] uncomment #chroot_local_user=YES"
sed -i 's/#chroot_local_user=YES/chroot_local_user=YES/g' /etc/vsftpd.conf

# add user_sub_token=$USER
echo "[*] add user_sub_token="
echo "user_sub_token=$USER" >> /etc/vsftpd.conf

# pasv port
echo "[*] set pasv port"
echo "pasv_min_port=40000" >> /etc/vsftpd.conf
echo "pasv_max_port=50000" >> /etc/vsftpd.conf

# userlist
echo "[*] make userlist"
echo "userlist_enable=YES" >> /etc/vsftpd.conf
echo "userlist_file=/etc/vsftpd.userlist" >> /etc/vsftpd.conf
echo "userlist_deny=NO" >> /etc/vsftpd.conf

# make array of users consists of admin, user1, user2, user3
users=(admin user1 user2 user3)

# for loop to add users to vsftpd.userlist
for i in "${users[@]}"
do
    echo "$i" >> /etc/vsftpd.userlist
done

# restart vsftpd service
systemctl restart vsftpd

# add users to the system with password of their username
for i in "${users[@]}"
do
    useradd -m -p $(openssl passwd -1 $i) $i
done

# create /ftp directory
mkdir /ftp

# change the owner of /ftp to nobody:nogroup
chown nobody:nogroup /ftp

# for loop to change all user home directory to /ftp
for i in "${users[@]}"
do
    usermod -d /ftp $i
done

# mkdir folder public inside /ftp
mkdir /ftp/public

# chown to admin:admin
chown admin:admin /ftp/public

# chmod to 755
chmod 755 /ftp/public

# create file inside /ftp/public
echo "This is a public file" > /ftp/public/public.txt

# chown to admin:admin
chown admin:admin /ftp/public/public.txt

# ufw allow all port 20, 21, 40000:50000
echo "[*] allow all port 20, 21, 40000:50000"
ufw allow 20/tcp
ufw allow 21/tcp
ufw allow 40000:50000/tcp

# print sucess message
echo "[*] FTP server is ready to use"

for i in "${users[@]}"
do
    echo "username: $i password: $i"
done