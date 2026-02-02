#! /bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/mongodb"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[0m"
SCRIPT_DIR=$(pwd)
MONGODB_HOST="mongodb.siddharthais.online"
MYSQL_HOST="mysql.siddharthais.online"

if [ $USERID -ne 0 ]; then
  echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
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

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Copying RabbitMQ Repo"

dnf install rabbitmq-server -y &>> $LOGS_FILE
VALIDATE $? "Installing RabbitMQ Server"

systemctl enable rabbitmq-server
systemctl start rabbitmq-server
VALIDATE $? " Enabling and starting RabbitMQ Service"

rabbitmqctl add_user roboshop roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATE $? "Creating RabbitMQ User and setting permissions"



