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

dnf install python3 gcc python3-devel -y &>> $LOGS_FILE
VALIDATE $? "Installing Maven"

id roboshop &>> $LOGS_FILE
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE
   VALIDATE $? "Adding sytem User"
else
    echo -e "$Y roboshop user already exists, skipping $N" | tee -a $LOGS_FILE
fi

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop

mkdir -p /app 
VALIDATE $? "Creating  Directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip $&>> $LOGS_FILE
VALIDATE $? "Downloading payment App"

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Cleaning old code"

unzip /tmp/payment.zip  $&>> $LOGS_FILE
VALIDATE $? "Unzippping payment code"

cd /app 
pip3 install -r requirements.txt $&>> $LOGS_FILE
VALIDATE $? "Installing payment Dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service $&>> $LOGS_FILE
VALIDATE $? "Copying payment Service File"

systemctl daemon-reload $&>> $LOGS_FILE

systemctl enable payment  $&>> $LOGS_FILE
systemctl start payment  $&>> $LOGS_FILE
VALIDATE $? "Starting and enabling payment"