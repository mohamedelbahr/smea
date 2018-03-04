#!/bin/bash


###########################################################
#########################Download composer################# 

echo "Installing composer file ..." 
EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig)
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")

if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
then
    >&2 echo 'ERROR: Invalid installer signature'
    rm composer-setup.php
    exit 1
fi

php composer-setup.php --quiet
RESULT=$?
rm composer-setup.php

echo "composer installed"
sleep 3

############################################################
############################################################


########### Read Mariadb root user name and password #######

echo -n Please enter Maria db admin account: 
read -s SQLROOT
echo

###################### Read Mariadb root Password ##########

echo -n Password: 
read -s SQLPASS
echo

###### Read desired password for user smea on maria db######

echo -n Please enter password for smea database that will be created: 
read -s SMEAPASS
echo

##### Create databse named "smea" and grant all privileges for user smea on it 

mysql -u$SQLROOT -p$SQLPASS -e "CREATE DATABASE smea"
mysql -u$SQLROOT -p$SQLPASS -e "GRANT ALL PRIVILEGES ON smea.* TO 'smea'@'localhost' IDENTIFIED BY '$SMEAPASS'"
echo "Database created and user smea grant access to it, Now cloning code from TFS repository ...."
sleep 3

# Clone code from TFS repository
git clone ssh://tfs.ibtikar.sa:1922/tfs/Ibtikar-Projects/SMEA/_git/SMEA_BackEnd

# Move composer binary file to system path
mv composer.phar /home/smea/bin

########### restore smea database from smea.sql backup file

mysql -u$SQLROOT -p$SQLPASS smea < $PWD/smea.sql
echo "Database restored successfully"
sleep 3

############ Install composer file

cd SMEA_BackEnd
composer install

############ Configure project parameters @ .env file
sed -n '1!N; s/DB_USERNAME=root\nDB_PASSWORD=/DB_USERNAME=smea\nDB_PASSWORD='$SMEAPASS'/; p' .env.example > .env

#############php artisan migrate

echo "Project is now running, Thank you"
sleep 3 


#http://www.refining-linux.org/archives/27/20-Multi-line-sed-search-and-replace/
