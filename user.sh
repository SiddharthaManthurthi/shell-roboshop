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

dnf module disable nodejs -y &>> $LOGS_FILE
VALIDATE $? "Disabling NodeJS Module"

dnf module enable nodejs:20 -y &>> $LOGS_FILE
VALIDATE $? "Enabling NodeJS 20 Module"

dnf install nodejs -y &>> $LOGS_FILE
VALIDATE $? "Installing NodeJS 20"

id roboshop &>> $LOGS_FILE
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE
   VALIDATE $? "Adding sytem User"
else
    echo -e "$Y roboshop user already exists, skipping $N" | tee -a $LOGS_FILE
fi

mkdir -p /app 
VALIDATE $? "Creating  Directory"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>> $LOGS_FILE
VALIDATE $? "Downloading user App" 

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Cleaning old code"

unzip /tmp/user.zip &>> $LOGS_FILE
VALIDATE $? "Unzippping user code"
 
npm install  &>> $LOGS_FILE
VALIDATE $? "Installing NodeJS Dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
VALIDATE $? "Copying user Service File"

systemctl daemon-reload
systemctl enable user  &>> $LOGS_FILE
systemctl start user
VALIDATE $? "Starting and enabling user Service"
