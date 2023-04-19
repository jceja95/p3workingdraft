#!/bin/bash
sudo su
yum update -y
yum install httpd -y
yum install mod_ssl -y
aws s3 cp s3://bboys-jd-test/index.html /var/www/html/index.html
#aws s3 cp s3://bboys-jd-test/httpd.conf /etc/httpd/conf/httpd.conf
aws s3 cp s3://bboys-jd-test/ssl.conf /etc/httpd/conf.d/ssl.conf
aws s3 cp s3://bboys-jd-test/localhost.crt /etc/pki/tls/certs
systemctl start httpd