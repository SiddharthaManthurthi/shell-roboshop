#! /bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$pwd
MYSQL_HOST="mysql.siddharthais.online"

if [ $USERID -ne 0 ]; then
  echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
  exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE () {
   if [ $1 -ne 0 ]; then
      echo -e "$2 ... $R installation failed $N" | tee -a $LOGS_FILE
      exit 1
    else
        echo -e "$2 ... $G installation successful $N" | tee -a $LOGS_FILE
    fi
}

dnf install maven -y &>> $LOGS_FILE
VALIDATE $? "Installing Maven"

id roboshop &>> $LOGS_FILE
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE
   VALIDATE $? "Adding sytem User"
else
    echo -e "$Y roboshop user already exists, skipping $N" | tee -a $LOGS_FILE
fi

mkdir -p /app 
VALIDATE $? "Creating APP Directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>> $LOGS_FILE
VALIDATE $? "Downloading shipping App"

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Cleaning old code"

unzip /tmp/shipping.zip &>> $LOGS_FILE
VALIDATE $? "Unzippping shipping code"

cd /app 
mvn clean package &>> $LOGS_FILE
VALIDATE $? "Building shipping code"

mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "Renaming shipping jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "Copying shipping Service File"

dnf install mysql -y &>> $LOGS_FILE
VALIDATE $? "Installing MySQL"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities'

if [ $? -ne 0 ]; then

    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql 
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql 
    VALIDATE $? "Loading shipping schema and data"
else
    echo -e "$Y shipping schema is already present, skipping $N" | tee -a $LOGS_FILE
fi

systemctl enable shipping 
systemctl start shipping
VALIDATE $? "Starting and enabling shipping"