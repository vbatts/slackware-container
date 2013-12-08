FROM vbatts/slackware
MAINTAINER Vincent Batts <vbatts@slackware.com>

RUN slackpkg install -batch=on -default_answer=y httpd-2.4.6-x86_64-1 apr-util-1.5.1-x86_64-1 sqlite-3.7.17-x86_64-1 cyrus-sasl-2.1.23-x86_64-5 apr-1.4.6-x86_64-1 
EXPOSE 80
ENTRYPOINT ["/usr/sbin/httpd","-X"]

# docker run -p 6666:80 vbatts/slackware-httpd 
