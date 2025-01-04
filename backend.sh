#!/bin/bash
LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

cd /var/log/expense-logs &>>$LOG_FILE_NAME
if [ $? -ne 0 ]
then
    echo "expense-logs directory not setup"
    mkdir -p /var/log/expense-logs
else
    echo "Already exists expense-logs directory"
fi

CHECKROOT(){
    USERID=$(id -u)
    if [ $USERID -ne 0 ]
    then
        echo "ERROR::You need sudo access to execute"
        exit 1
    fi
}

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo "$2...FAILURE"
        exit 1
    else
        echo "$2...SUCCESS"
    fi
}

echo "Started executing script at :: $TIMESTAMP" &>>$LOG_FILE_NAME
CHECKROOT

dnf module disable nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Disabling existing default NodeJS"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "Enabling NodeJS 20"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing NodeJS"

id expense &>>$LOG_FILE_NAME
if [ $? -ne 0 ]
then
    useradd expense &>>$LOG_FILE_NAME
    VALIDATE $? "Adding expense user"
else
    echo "expense user already exists ...SKIPPING"
fi

cd /app &>>$LOG_FILE_NAME
if [ $? -ne 0 ]
then
    echo "app directory not created"
    mkdir -p /app
else
    echo "Already exists app directory"
fi

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading backend"

cd /app
rm -rf /app/*

unzip /tmp/backend.zip &>>$LOG_FILE_NAME
VALIDATE $? "unzip backend"

npm install &>>$LOG_FILE_NAME
VALIDATE $? "Installing dependencies"

cp /opt/expense-shell/backend.service /etc/systemd/system/backend.service

dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing MySQL Client"

mysql -h mysql.daws-82s.site -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE_NAME
VALIDATE $? "Setting up the transactions schema and tables"

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "Daemon Reload"

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "Enabling backend"

systemctl restart backend &>>$LOG_FILE_NAME
VALIDATE $? "Starting Backend"