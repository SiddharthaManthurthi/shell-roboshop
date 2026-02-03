#!/bin/bash

LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

SCRIPT_DIR=$PWD
MYSQL_HOST=mysql.siddharthais.online

USERID=$(id -u)

if [ $USERID -ne 0 ]; then
   echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
   exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e " $2 ...$R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e " $2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
    }

dnf install maven -y &>> $LOGS_FILE
VALIDATE $? "Installing Maven ..."

id roboshop &>> $LOGS_FILE
    if [ $? -ne 0 ]; then
         useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE
         VALIDATE $? "Creating system user"
    else
        echo -e "Already exist ... $Y Skipping it $N"

    fi

mkdir -p /app &>> $LOGS_FILE
VALIDATE $? "App directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>> $LOGS_FILE
VALIDATE $? "Download the code"

cd /app &>> $LOGS_FILE
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/shipping.zip &>> $LOGS_FILE
VALIDATE $? "Unzip the code"

mvn clean package &>> $LOGS_FILE
VALIDATE $? "Clean the default package"

mv target/shipping-1.0.jar shipping.jar &>> $LOGS_FILE
VALIDATE $? "Renaming jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>> $LOGS_FILE
VALIDATE $? "Copying shipping service"

systemctl daemon-reload &>> $LOGS_FILE
VALIDATE $? "Reload the service"

dnf install mysql -y &>> $LOGS_FILE
VALIDATE $? "Install mysql"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>> $LOGS_FILE
VALIDATE $? "Creating shipping schema"
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>> $LOGS_FILE
VALIDATE $? "Creating shipping app user"
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>> $LOGS_FILE
VALIDATE $? "Loading shipping master data"

systemctl enable shipping &>> $LOGS_FILE
VALIDATE $? "Enable the shipping service"

systemctl start shipping &>> $LOGS_FILE
VALIDATE $? "Start the shipping service" 
