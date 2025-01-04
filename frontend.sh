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

dnf install nginx -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing Nginx Server"

systemctl enable nginx &>>$LOG_FILE_NAME
VALIDATE $? "Enabling Nginx server"

systemctl start nginx &>>$LOG_FILE_NAME
VALIDATE $? "Starting Nginx Server"

rm -rf /usr/share/nginx/html/*
VALIDATE $? "Removing existing code"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading Latest code"

cd /usr/share/nginx/html
VALIDATE $? "Moving to HTML directory"

unzip /tmp/frontend.zip
VALIDATE $? "unzipping the frontend.zip"

cp /opt/expense-shell/expense.conf /etc/nginx/default.d/expense.conf
VALIDATE $? "Copied expense config"

systemctl restart nginx &>>$LOG_FILE_NAME
VALIDATE $? "Restarting nginx"