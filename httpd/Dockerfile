FROM vbatts/slackware
MAINTAINER Vincent Batts <vbatts@slackware.com>

RUN slackpkg -batch=on -default_answer=y update
RUN slackpkg -batch=on -default_answer=y install httpd-2.4.6-x86_64-1 apr-util-1.5.1-x86_64-1 sqlite-3.7.17-x86_64-1 cyrus-sasl-2.1.23-x86_64-5 apr-1.4.6-x86_64-1
RUN chmod +x /etc/rc.d/rc.httpd
EXPOSE 80
VOLUME ["/var/www","/etc/httpd","/var/log/httpd"]
ENTRYPOINT ["sh","-c", "/usr/sbin/httpd -DFOREGROUND"]

# docker run -p 6666:80 vbatts/slackware-httpd 
