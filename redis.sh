#! /bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/mongodb"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[0m"

if [ $USERID -ne 0 ]; then
  echo -e "$R Please run this script with root  access $N" | tee -a $LOGS_FILE
  exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE () {
   if [ $1 -ne 0 ]; then
      echo -e "$R $2 installation failed $N" | tee -a $LOGS_FILE
      exit 1
    else
        echo -e "$G $2 installation successful $N" | tee -a $LOGS_FILE
    fi
}

dnf module disable redis -y &>> $LOGS_FILE
VALIDATE $? "Disabling Redis Module"

dnf module enable redis:7 -y &>> $LOGS_FILE
VALIDATE $? "Enabling Redis 7 Module"

dnf install redis -y  &>> $LOGS_FILE
VALIDATE $? "Installing Redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Updating Redis Configuration"

systemctl enable redis &>> $LOGS_FILE
VALIDATE $? "Enabling Redis Service"

systemctl start redis &>> $LOGS_FILE
VALIDATE $? "Starting Redis Service"