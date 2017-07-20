#!/bin/bash
# FTP installer for Debian, Ubuntu and CentOS/Redhat
# Created by Vlku 10/7/2017 - vlku@null.net

# This script will work on Debian, Ubuntu, CentOS and probably other distros
# of the same families, although no support is offered for them. It isn't
# bulletproof but it will probably work if you simply want to setup a FTP on
# your Debian/Ubuntu/CentOS box. It has been designed to be as unobtrusive and
# universal as possible.
clear

###########################
##### FUNCTIONS PART ######
###########################

checkRoot() {
   if [ $(id -u) -ne 0 ]; then
     echo "Sorry, you need to run this as root \n"
     exit 1
   fi
}
echo -e "\n\n\t \e[1;32m Make sure you have repo for installing packages \e[0m \n"

check_conf()
{
if [ -f "/etc/vsftpd/vsftpd.conf" ];
then
        true
else
        echo -e "\n\t \e[1;31m Install the package first. vsftpd conf file does not exists! \e[0m \n"
        exit 1
fi
}

ftps_install()
{
while :
do
echo -n -e "\n\tDo you want FTPS:[\e[1;32mYes\e[0m/\e[1;31mNo\e[0m] "
read f
case $f in
        [yY]|[yY][eE][sS])
                echo -n -e "\nInstalling FTPS "
                echo -n -e "\nPlease enter the required values for gererating certificate: "
        cd /etc/vsftpd
        openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout vsftpd.pem -out vsftpd.pem
        echo -e "\n" >> /etc/vsftpd/vsftpd.conf
        echo "#For FTPS" >> /etc/vsftpd/vsftpd.conf
        echo "ssl_enable=YES" >> /etc/vsftpd/vsftpd.conf
        echo "allow_anon_ssl=YES" >> /etc/vsftpd/vsftpd.conf
        echo "force_local_data_ssl=YES" >> /etc/vsftpd/vsftpd.conf
        echo "force_local_logins_ssl=YES" >> /etc/vsftpd/vsftpd.conf
        echo "ssl_tlsv1=YES" >> /etc/vsftpd/vsftpd.conf
        echo "ssl_sslv2=YES" >> /etc/vsftpd/vsftpd.conf
        echo "ssl_sslv3=YES" >> /etc/vsftpd/vsftpd.conf
        echo "rsa_cert_file=/etc/vsftpd/vsftpd.pem" >> /etc/vsftpd/vsftpd.conf
        echo -e "\n\n\t \e[1;32m NOTE:- if you are using FTPS server and filezilla as your client make sure you go to EditΦsettingsΦActive mode  and select Get external Ip address from the following URL and also make sure you select Don’t use external Ip address on local connections. \e[0m \n"
        break
        ;;
        [nN]|[nN][oO])
                echo -n -e "\nInstalling only FTP. Recomended to use FTPS"
                break
        ;;
        *)
                echo -e "\n\t \e[1;31m Bad argument! \e[0m "
        ;;
esac
done
}
install()
{
if [ -f "/etc/vsftpd/vsftpd.conf" ];
then
        echo -e "\n\t\e[1;32mAlready installed\e[0m"
else
        yum clean all > /dev/null
        yum install vsftpd ftp -y > /dev/null
        check_conf
        sed -i 's/^anonymous_enable=YES/anonymous_enable=NO/g' /etc/vsftpd/vsftpd.conf
        sed -i '/chroot_list_enable/s/^#//g' /etc/vsftpd/vsftpd.conf
        sed -i '/chroot_list_file/s/^#//g' /etc/vsftpd/vsftpd.conf
        ftps_install
        echo -e "\n" >> /etc/vsftpd/vsftpd.conf
        echo "#For Logs" >> /etc/vsftpd/vsftpd.conf
        echo "dual_log_enable=YES" >> /etc/vsftpd/vsftpd.conf
        echo "xferlog_file=/var/log/vsftpd.log" >> /etc/vsftpd/vsftpd.conf
        echo "log_ftp_protocol=YES" >> /etc/vsftpd/vsftpd.conf
        setsebool -P ftp_home_dir on
        touch /var/log/vsftpd.log
                if [ -f "/etc/vsftpd/chroot_list" ];
                then
                        true
                else
                        touch /etc/vsftpd/chroot_list
                fi
        service vsftpd restart
        chkconfig vsftpd on
        systemctl enable vsftpd
echo -e "\n\n\t \e[1;32m Installation of packages and configuration completed \e[0m \n"
fi
}

check_user()
{
awk -F ":" {'print $1'} /etc/passwd | egrep "^$u1$" > /dev/null
        if [ $? -eq 0 ]; then
                cat /etc/vsftpd/chroot_list | egrep "^$u1$" > /dev/null
                if [ $? -eq 0 ]; then
                        echo -e "\n\t\e[1;32m$u1\e[0m \e[1;31muser Already chrooted \e[0m "
                else
                        echo $u1 >> /etc/vsftpd/chroot_list
                        echo -e "\n\t\e[1;32m$u1 chrooted successfully \e[0m"
                fi
        else
                echo -e "\n\t\e[1;32m$u1\e[0m \e[1;31m user does not exist! \e[0m \n"
        fi
}
chrooting_a()
{
while :
do
echo -n -e "\n\tDo you want to chroot another ftp user:[\e[1;32mYes\e[0m/\e[1;31mNo\e[0m] "
read oo
case $oo in
        [yY]|[yY][eE][sS])
                echo -n -e "\nPlease enter the another username to chroot: "
                read u1
                check_user
        ;;
        [nN]|[nN][oO])
                break
        ;;
        *)
                echo -e "\n\t \e[1;31m Bad argument! \e[0m "
        ;;
esac
done
}
chrooting()
{
while :
do
echo -n -e "\n\tDo you want to chroot \e[1;32m$u1\e[0m user:[\e[1;32mYes\e[0m/\e[1;31mNo\e[0m] "
read ooo
case $ooo in
        [yY]|[yY][eE][sS])
                check_user
                break
        ;;
        [nN]|[nN][oO])
                break
        ;;
        *)
                echo -e "\n \e[1;31m Bad argument! \e[0m "
        ;;
esac
done
}

up_adding()
{
                        useradd $u1
p1=$u1@$(id $u1 | awk -F "=" {'print $2'} | awk -F "(" {'print $1'})*
                        echo -e "$p1\n$p1\n\n" | passwd $u1
                        echo -e "\n\tThe password for user \e[1;32m$u1\e[0m is \e[1;32m$p1\e[0m"
                        chrooting
}
addinguser_a()
{
while :
do
echo -n -e "\n\tDo you want to add another ftp user:[\e[1;32mYes\e[0m/\e[1;31mNo\e[0m] "
read oo
case $oo in
        [yY]|[yY][eE][sS])
                echo -n -e "\nPlease enter the another username for ftpuser: "
                read u1
                awk -F ":" {'print $1'} /etc/passwd | egrep "^$u1$" > /dev/null
                if [ $? -eq 0 ]; then
                        echo -e "\n\t \e[1;32m$u1\e[0m \e[1;31m user Already exists! \e[0m "
                else
                        up_adding
                fi
        ;;
        [nN]|[nN][oO])
                break
        ;;
        *)
                echo -e "\n\t \e[1;31m Bad argument! \e[0m "
        ;;
esac
done
}
addinguser()
{
while :
do
echo -n -e "\n\tAdding the ftp user:[\e[1;32mYes\e[0m/\e[1;31mNo\e[0m] "
read o
case $o in
  [yY]|[yY][eE][sS])
        echo -n -e "\nPlease enter the username for ftpuser: "
        read u1
        awk -F ":" {'print $1'} /etc/passwd | egrep "^$u1$" > /dev/null
        if [ $? -eq 0 ]; then
                echo -e "\n\t \e[1;32m$u1\e[0m \e[1;31m user Already exists! \e[0m "
        else
                up_adding
        fi
        addinguser_a
        break
        ;;
 [nN]|[nN][oO])
        echo -e "\n"
        break
        ;;
 *)
        echo -e "\n\t \e[1;31m Bad argument! \e[0m "
        ;;
esac
done
}

rc_check_user()
{
awk -F ":" {'print $1'} /etc/passwd | egrep "^$u1$" > /dev/null
        if [ $? -eq 0 ]; then
                cat /etc/vsftpd/chroot_list | egrep "^$u1$" > /dev/null
                if [ $? -eq 0 ]; then
                        sed -i 's#^'$u1'$##' /etc/vsftpd/chroot_list && sed -i '/^$/d' /etc/vsftpd/chroot_list
                        echo -e "\n\t\e[1;32m$u1 un chrooted successfully \e[0m"
                else
                        echo -e "\n\t\e[1;32m$u1 is already un chrooted \e[0m"
                fi
        else
                echo -e "\n\t\e[1;32m$u1\e[0m \e[1;31m user does not exist! \e[0m \n"
        fi
}
removechroot_a()
{
while :
do
echo -n -e "\n\tDo you want to removing chroot for another ftp user:[\e[1;32mYes\e[0m/\e[1;31mNo\e[0m] "
read oo
case $oo in
        [yY]|[yY][eE][sS])
                echo -n -e "\nPlease enter the another username to remove chroot: "
                read u1
                rc_check_user
        ;;
        [nN]|[nN][oO])
                break
        ;;
        *)
                echo -e "\n\t \e[1;31m Bad argument! \e[0m "
        ;;
esac
done
}
removechroot()
{
while :
do
echo -n -e "\n\tDo you want to removing chroot for ftp user: \e[1;32m$u1\e[0m user:[\e[1;32mYes\e[0m/\e[1;31mNo\e[0m] "
read ooo
case $ooo in
        [yY]|[yY][eE][sS])
               rc_check_user
                break
        ;;
        [nN]|[nN][oO])
                break
        ;;
        *)
                echo -e "\n \e[1;31m Bad argument! \e[0m "
        ;;
esac
done
}

du_check_user()
{
awk -F ":" {'print $1'} /etc/passwd | egrep "^$u1$" > /dev/null
        if [ $? -eq 0 ]; then
                        while :
                        do
                        echo -e "\n\t  1\e[1;32m : \e[0mTo remove ftp user along with home directory \n\n\t  2\e[1;32m : \e[0mTo remove only ftp user \n"
                        read -p "enter the option number : " oo
                        case $oo in
                                1)
                                   /usr/sbin/userdel -rf $u1
                                        break
                                ;;
                                2)
                                   /usr/sbin/userdel $u1
                                        break
                                ;;
                                *)
                                        echo -e "\n\t \e[1;31m Bad argument! \e[0m "
                                ;;
                        esac
                        done
                        echo -e "\n\t\e[1;32m$u1 removed successfully \e[0m"
                else
                echo -e "\n\t\e[1;32m$u1\e[0m \e[1;31m user does not exist! \e[0m \n"
        fi
}
deleteuser_a()
{
while :
do
echo -n -e "\n\tDo you want to remove another ftp user:[\e[1;32mYes\e[0m/\e[1;31mNo\e[0m] "
read oo
case $oo in
        [yY]|[yY][eE][sS])
                echo -n -e "\nPlease enter the another username to delete: "
                read u1
                du_check_user
        ;;
        [nN]|[nN][oO])
                break
        ;;
        *)
                echo -e "\n\t \e[1;31m Bad argument! \e[0m "
        ;;
esac
done
}
deleteuser()
{
while :
do
echo -n -e "\n\tDo you want to remove ftp \e[1;32m$u1\e[0m user:[\e[1;32mYes\e[0m/\e[1;31mNo\e[0m] "
read ooo
case $ooo in
        [yY]|[yY][eE][sS])
               du_check_user
                break
        ;;
        [nN]|[nN][oO])
                break
        ;;
        *)
                echo -e "\n \e[1;31m Bad argument! \e[0m "
        ;;
esac
done
}

enable_ftp_user_check_user()
{
awk -F ":" {'print $1'} /etc/passwd | egrep "^$u1$" > /dev/null
        if [ $? -eq 0 ]; then
                cat /etc/vsftpd/ftpusers | egrep "^$u1$" > /dev/null && cat /etc/vsftpd/user_list | egrep "^$u1$" > /dev/null
                if [ $? -eq 0 ]; then
                        sed -i 's#^'$u1'$##' /etc/vsftpd/ftpusers; sed -i '/^$/d' /etc/vsftpd/ftpusers && sed -i 's#^'$u1'$##' /etc/vsftpd/user_list; sed -i '/^$/d' /etc/vsftpd/user_list
                        echo -e "\n\t\e[1;32m$u1 ftp enabled \e[0m"
                else
                        echo -e "\n\t\e[1;32m$u1 is already enabled \e[0m"
                fi
        else
                echo -e "\n\t\e[1;32m$u1\e[0m \e[1;31m user does not exist! \e[0m \n"
        fi
}
enable_ftp_user_a()
{
while :
do
echo -n -e "\n\tDo you want to enable FTP for another user:[\e[1;32mYes\e[0m/\e[1;31mNo\e[0m] "
read oo
case $oo in
        [yY]|[yY][eE][sS])
                echo -n -e "\nPlease enter the another username to enable FTP: "
                read u1
                enable_ftp_user_check_user
        ;;
        [nN]|[nN][oO])
                break
        ;;
        *)
                echo -e "\n\t \e[1;31m Bad argument! \e[0m "
        ;;
esac
done
}
enable_ftp_user()
{
while :
do
echo -n -e "\n\tDo you want to enable FTP for user: \e[1;32m$u1\e[0m user:[\e[1;32mYes\e[0m/\e[1;31mNo\e[0m] "
read ooo
case $ooo in
        [yY]|[yY][eE][sS])
                enable_ftp_user_check_user
                break
        ;;
        [nN]|[nN][oO])
                break
        ;;
        *)
                echo -e "\n \e[1;31m Bad argument! \e[0m "
        ;;
esac
done
}

disable_ftp_user_check_user()
{
awk -F ":" {'print $1'} /etc/passwd | egrep "^$u1$" > /dev/null
        if [ $? -eq 0 ]; then
                cat /etc/vsftpd/ftpusers | egrep "^$u1$" > /dev/null && cat /etc/vsftpd/user_list | egrep "^$u1$" > /dev/null
                if [ $? -eq 0 ]; then
                        echo -e "\n\t\e[1;32m$u1\e[0m \e[1;31muser FTP Already disabled \e[0m "
                else
                        echo $u1 >> /etc/vsftpd/ftpusers && echo $u1 >> /etc/vsftpd/user_list
                        echo -e "\n\t\e[1;32m$u1 disabled successfully \e[0m"
                fi
        else
                echo -e "\n\t\e[1;32m$u1\e[0m \e[1;31m user does not exist! \e[0m \n"
        fi
}
disable_ftp_user_a()
{
while :
do
echo -n -e "\n\tDo you want to disable FTP for another ftp :[\e[1;32mYes\e[0m/\e[1;31mNo\e[0m] "
read oo
case $oo in
        [yY]|[yY][eE][sS])
                echo -n -e "\nPlease enter the another username to disable FTP: "
                read u1
                disable_ftp_user_check_user
        ;;
        [nN]|[nN][oO])
                break
        ;;
        *)
                echo -e "\n\t \e[1;31m Bad argument! \e[0m "
        ;;
esac
done
}
disable_ftp_user()
{
while :
do
echo -n -e "\n\tDo you want to disable FTP for \e[1;32m$u1\e[0m user:[\e[1;32mYes\e[0m/\e[1;31mNo\e[0m] "
read ooo
case $ooo in
        [yY]|[yY][eE][sS])
                disable_ftp_user_check_user
                break
        ;;
        [nN]|[nN][oO])
                break
        ;;
        *)
                echo -e "\n \e[1;31m Bad argument! \e[0m "
        ;;
esac
done
}

###########################
##### MAIN CODE PART ######
###########################

while :
do
checkRoot
echo -e "\n \e[1;32m choose any one option for ftp:- \e[0m \n\n  1\e[1;32m : \e[0mTo install package and configure \n\n  2\e[1;32m : \e[0mTo add user \n\n  3\e[1;32m : \e[0mTo chroot(Restrict ftp user to his home directory) existing user \n\n  4\e[1;32m : \e[0mTo remove chroot(Un Restrict ftp user to his home directory) for user \n\n  5\e[1;32m : \e[0mTo enable FTP for a user \n\n  6\e[1;32m : \e[0mTo disable FTP for a user \n\n  7\e[1;32m : \e[0mTo delete user \n\n  8\e[1;32m : \e[0mTo see the FTP Login details \n\n  9\e[1;32m : \e[0mTo see the Failed FTP Login details \n\n  10\e[1;32m : \e[0mTo see the UPLOAD (or) EDIT and DOWNLOAD FTP activity log \n\n  11\e[1;32m : \e[0mTo see the DELETE FTP activity log \n\n  Q\e[1;32m : \e[0mExit"
read -p "enter the option number : " OPT
case $OPT in
  1)
        install
        ;;
  2)
        check_conf
        addinguser
        ;;
  3)
        check_conf
        echo -n -e "\nPlease enter the username to chroot: "
        read u1
        chrooting
        chrooting_a
        ;;
  4)
        check_conf
        echo -n -e "\nPlease enter the username to un chroot: "
        read u1
        removechroot
        removechroot_a
        ;;
  5)
        check_conf
        echo -n -e "\nPlease enter the username to enable FTP: "
        read u1
        enable_ftp_user
        enable_ftp_user_a
        ;;
  6)
        check_conf
        echo -n -e "\nPlease enter the username to disable FTP: "
        read u1
        disable_ftp_user
        disable_ftp_user_a
        ;;
  7)
        check_conf
        echo -n -e "\nPlease enter the username to delete ftp user: "
        read u1
        deleteuser
        deleteuser_a
        ;;
  8)
        echo -e "\n\t \e[1;32m FTP LOGIN DETAILS ARE:- \e[0m \n"
        echo -e "TIME STAMP\t\t\tUSERNAME\tIPADDRESS" && tail -1000 /var/log/vsftpd.log | grep "Login successful" | awk  '{print $1,$2,$3,$4,$5,"\t"$8,"\t"$9,"\t"$12}' | tr -d '()[]{}",'
        ;;
  9)
        echo -e "\n\t \e[1;32m FAILED FTP LOGIN DETAILS ARE:- \e[0m \n"
        echo -e "TIME STAMP\t\t\tUSERNAME\tIPADDRESS" && tail -1000 /var/log/vsftpd.log | grep "Login incorrect" | awk  '{print $1,$2,$3,$4,$5,"\t"$8,"\t"$9,"\t"$12}' | tr -d '()[]{}",'
        ;;
  10)
        echo -e "\n\t \e[1;32m FTP UPLOAD (or) EDIT and DOWNLOAD DETAILS ARE:- \e[0m \n\n\t \e[1;32m IN THE FOURTH FIELD: \e[0m \n\t \e[1;32m i ==> UPLOAD (or) EDITED \e[0m \n\t \e[1;32m o ==> DOWNLOAD \e[0m \n"
        tail -1000 /var/log/vsftpd.log | grep "b _ o \| b _ i \|a _ o \|a _ i" | awk  '{print $1,$2,$3,$4,$5,"\t"$7,"\t"$9,"\t"$12,"\t"$14}' | tr -d '/'
        ;;
  11)
        echo -e "\n\t \e[1;32m THE FTP DELETED FILE'S DETAILS ARE:- \e[0m \n"
        tail -1000 /var/log/vsftpd.log | grep "OK DELETE:" | awk '{$6=$7=$9=$10=$11=""; print $0}' | tr -d '/[]",'
        ;;
  q|Q)
        echo -e "\n\t \e[1;31m Bye! \e[0m \n"
        exit 0
        ;;
  *)
        clear
        echo -e "\n \e[1;31m Bad argument! \e[0m \n"
        ;;
esac
done