#!/bin/bash
#-------------------------------Settings section-------------------------------------
###
###Configure locations
###
####Put your backup target here, i.e it can be a pendrive mounted in /mnt/usb
backup_target=/mnt/usb

####Choose temporary location for files before copying to backup location
temp=/var/tmp

####Choose where are apache config files you want to backup, be default in Debian/Ubuntu/Raspbian it's /etc/apache2/sites-available
apache_config=/etc/apache2/sites-available

####Where are your website(s) located?
websites=/var/www

###
###MySQL settings
###
username=
password=
database_list='wordpress_db' #you can add more databases with space 'wordpress_db phpmyadmin mydatabase'
host= #localhost in most cases

#how many days should files remain in backup location? Put 7 if you want to delete backups older then one week.
age=7
#------------------------------End of settings section------------------------------

#------------------------------Welcome message--------------------------------------
now=$(date +"%d.%m.%Y %H:%M")
echo "-------------------------------------------"
echo "Backup script started at: $now"
echo "-------------------------------------------"
#-------------------------------End of welcome message------------------------------



#-----------------------------Checking folders section------------------------------
###
###Checking directories and makeing them if not exists
###

####Backup directory for websites files
if [ ! -d "$backup_target/www" ]
then
	echo "Directory /www  does not exists in backup target. Creating a directory."
	sudo mkdir -p $backup_target/www/
fi

####Backup directory for databases
if [ ! -d "$backup_target/databases" ]
then
        echo "Directory /databases does not exists in backup target. Creating a directory."
        sudo mkdir -p $backup_target/databases
fi

####Backup directory for apache configuration files
if [ ! -d "$backup_target/apache" ]
then
        echo "Directory /apache does not exists in backup target. Creating a directory."
        sudo mkdir -p $backup_target/apache
fi
echo ""
#------------------------End of checking folders section-----------------------------



#-------------------------Cleaning section-------------------------------------------
echo "Cleaning old backups"
sudo find $backup_target/databases -type f -mtime +$age -name '*.gz' -execdir rm -- '{}' \;


if [ "$(ls -A $backup_target/www)" ]; then #checking if backup directory is empty to avoid error on initial run
	sudo rdiff-backup --remove-older-than ${age}D $backup_target/www
fi
echo ""


#-------------------------End of cleaning section-------------------------------------------

#------------------------Backup job section------------------------------------------
###
###Backing up websites files
###
echo "Backing up websites files"
sudo rdiff-backup -v 3 $websites $backup_target/www
echo ""
###
###Backing up databases
###
echo "Backing up databases"
for base in $database_list
do
	now=$(date +"%d_%m_%Y_%H_%M")
	filename=${base}_${now}.sql.gz
	mysqldump -h $host -u $username -p$password $base | gzip > $temp/$filename
	sudo mv $temp/$filename $backup_target/databases/$filename
	if [ -f "$backup_target/databases/$filename" ]
	then
		filesize=$(stat -c%s "$backup_target/databases/$filename")
		echo "$filename succesfully copied to backup target, filesize is: $filesize KB" #info to verify in logs
	else
		echo "File $filename was not copied properly to backup target!" #info to verify in logs
	fi
done
echo ""
###
###Backing up apache confing files
###
echo "Backing up apache config files"
sudo rdiff-backup -v 3 $apache_config $backup_target/apache
echo ""

#-------------------------End of backing up section-------------------------------

#------------------------------Bye------------------------------------------------
now=$(date +"%d.%m.%Y %H:%M")
echo "-------------------------------------------"
echo "Backup finished at: $now, bye."
echo "-------------------------------------------"
