#!/bin/bash
LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

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

cd /var/log/expense-logs &>>$LOG_FILE_NAME
if [ $? -ne 0 ]
then
    echo "expense-logs directory not setup"
    mkdir -p /var/log/expense-logs
else
    echo "Already exists expense-logs directory"
fi

dnf install mysql-server -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing MySQL"

systemctl enable mysqld &>>$LOG_FILE_NAME
VALIDATE $? "Enabling mysql"

systemctl start mysqld &>>$LOG_FILE_NAME
VALIDATE $? "Starting mysql"

mysql -h mysql.daws-82s.site -u root -pExpenseApp@1 -e 'show databases;' &>>$LOG_FILE_NAME

if [ $? -ne 0 ]
then
    echo "MySQL Root password not setup" &>>$LOG_FILE_NAME
    mysql_secure_installation --set-root-pass ExpenseApp@1
    VALIDATE $? "Setting Root Password"
else
    echo -e "MySQL Root password already setup ... $Y SKIPPING $N"
fi