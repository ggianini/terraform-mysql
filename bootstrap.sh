#Installing and enabling mysql

echo mbas3cr37p4ssw0rd2! | sudo -S yum -y install wget
sudo wget https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm
sudo rpm -ivh mysql57-community-release-el7-9.noarch.rpm
sudo yum -y install mysql-server
sudo systemctl enable --now mysqld
sudo systemctl status mysqld

#Defining Variables - must be placed after installing MySQL

TEMP_PWD=$(sudo grep 'A temporary password is generated for root@localhost:' /var/log/mysqld.log | awk '{print $NF}') #This is the temporary password automatically generated when installing mysql
NEW_PWD='mbas3cr37p4ssw0rd2!'
NEW_PWD_LENGHT=${#NEW_PWD}

#Configuring /etc/my.cnf

sudo setenforce 0

sudo echo "bind-address = 0.0.0.0" | sudo tee -a /etc/my.cnf
sudo systemctl restart mysqld

#Configuring password and privileges
mysql -uroot -p$TEMP_PWD --connect-expired-password -e "SET password FOR root@localhost=password('$TEMP_PWD');"
mysql -uroot -p$TEMP_PWD -e "SET GLOBAL validate_password_length=($NEW_PWD_LENGHT);"
mysql -uroot -p$TEMP_PWD -e "SET GLOBAL validate_password_policy=LOW;"
mysql -uroot -p$TEMP_PWD -e "SET password for root@localhost=password('$NEW_PWD');"
mysql -uroot -p$NEW_PWD -e "SELECT host FROM mysql.user WHERE User = 'root';"
mysql -uroot -p$NEW_PWD -e "CREATE USER 'root'@'%' IDENTIFIED BY '$NEW_PWD';"
mysql -uroot -p$NEW_PWD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%'"
mysql -uroot -p$NEW_PWD -e "flush privileges;"
mysql -uroot -p$NEW_PWD -e "SELECT host FROM mysql.user WHERE User = 'root';"

#Creating and populating database

mysql -uroot -p$NEW_PWD -e "CREATE DATABASE mbadb;"
mysql -uroot -p$NEW_PWD mbadb -e "CREATE TABLE mbatable (id INT NOT NULL, nome VARCHAR(50) NOT NULL, PRIMARY KEY (id));"
mysql -uroot -p$NEW_PWD mbadb -e "INSERT INTO mbatable (id,nome) VALUES(1,'Gustavo Gianini');"
mysql -uroot -p$NEW_PWD mbadb -e "INSERT INTO mbatable (id,nome) VALUES(2,'MBA');"
mysql -uroot -p$NEW_PWD mbadb -e "INSERT INTO mbatable (id,nome) VALUES(3,'DevOps');"
mysql -uroot -p$NEW_PWD mbadb -e "SELECT * FROM mbatable;"

sudo echo "skip-grant-tables" | sudo tee -a /etc/my.cnf
sudo systemctl restart mysqld
