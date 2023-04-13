#!/bin/bash
sudo su
yum update -y
yum install httpd -y
aws s3 cp s3://bboys-jd-test/index.html /var/www/html/index.html
systemctl start httpd