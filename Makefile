project=lampshade
webroot=/export/
srcdir=/usr/src/
zlib=zlib-1.2.5
libxml2=libxml2-git-snapshot.tar.gz
m4=m4-latest.tar.gz
autoconf=autoconf-2.13
http=httpd-2.2.19
curl=curl-7.21.2
gd=gd-2.0.35
mysql=mysql-5.5.14
openssl=openssl-1.0.0a
php=php-5.3.3
libpng=libpng-1.5.2
cmake=cmake-2.8.4


# ubuntu users should install the following packages first. Users of other distros should install their equivalents:

# libncurses5-dev
# subversion


all: cmake zlib m4 autoconf libxml2 openssl apache mysql curl libjpeg png php extensions 

cmake:
	## more recent MySQL builds require cmake - Oracle have done some work here :)
	cd ${srcdir}; [ ! -e ${cmake}.tar.gz ] && wget http://www.cmake.org/files/v2.8/${cmake}.tar.gz ; tar -zxvf ${cmake}.tar.gz && cd ${cmake} && ./configure && make && make install

libxml2:
	## install libxml2
	cd ${srcdir}; [ ! -e libxml2-git-snapshot.tar.gz ] && wget ftp://xmlsoft.org/libxml2/libxml2-git-snapshot.tar.gz ; tar -zvxf libxml2-git-snapshot.tar.gz && cd libxml* && ./configure && make && make install

zlib: 
	## install zlib
	cd ${srcdir}; [ ! -e ${zlib}.tar.gz ] && wget http://www.zlib.net/${zlib}.tar.gz ; tar -zvxf ${zlib}.tar.gz && cd ${zlib}/ && ./configure && make test && make install 

png:
	cd ${srcdir}; [ ! -e ${libpng}.tar.gz ] && wget ftp://ftp.simplesystems.org/pub/libpng/png/src/${libpng}.tar.gz ; tar -zxvf ${libpng}.tar.gz && cd ${libpng}/ && ./configure && make && make install

m4:
	## install m4
	cd ${srcdir} ; [ ! -e m4-latest.tar.gz ] && wget http://ftp.gnu.org/gnu/m4/m4-latest.tar.gz ; tar -zvxf m4-latest.tar.gz && cd m4* && ./configure && make && make install 

autoconf:
	## install autoconf
	cd ${srcdir} ; [ ! -e ${autoconf}.tar.gz ] && wget http://ftp.gnu.org/gnu/autoconf/${autoconf}.tar.gz ; tar -zvxf ${autoconf}.tar.gz && cd ${autoconf}/ && ./configure && make && make install

apache:
	## install apache
	cd ${srcdir} ; [ ! -e ${http}.tar.gz ] && wget http://mirrors.ukfast.co.uk/sites/ftp.apache.org/httpd/${http}.tar.gz ; tar -zxvf ${http}.tar.gz && cd ${http}/ && ./configure --enable-so --enable-rewrite --enable-deflate --enable-expires && make && make install

curl:
	## install curl
	cd ${srcdir} ; [ ! -e ${curl}.tar.gz ] && wget http://curl.haxx.se/download/${curl}.tar.gz ; tar -zxvf ${curl}.tar.gz && cd ${curl} && ./configure && make && make install

libjpeg:
	## install libjpeg
	cd ${srcdir} ; [ ! -e jpegsrc.v7.tar.gz ] && wget http://www.ijg.org/files/jpegsrc.v7.tar.gz ; tar -zxvf jpegsrc.v7.tar.gz && cd jpeg-7 && ./configure &&  make && make install && make install-libLTLIBRARIES

	## copy shared object into a place where php's configure can find it
	if [ -f /usr/local/lib/libjpeg.so ] ; then echo "libjpeg.so already in place."; else echo "Copying new libjpeg shared object into /usr/local/lib/libjpeg.so"; cp /usr/local/lib/libjpeg.so.7.0.0 /usr/lib/libjpeg.so; fi

mysql:
	## build the mysql server and client libs
	useradd mysql;  cd ${srcdir}; [ ! -e ${mysql}.tar.gz ] && wget http://www.mirrorservice.org/sites/ftp.mysql.com/Downloads/MySQL-5.5/${mysql}.tar.gz ; mv ${srcdir}index.html ${srcdir}${mysql}; tar -zxvf ${mysql}.tar.gz && cd ${srcdir}${mysql} && [ -e CMakeCache.txt ] && rm CMakeCache.txt ; cmake . ; make && make install && cp support-files/my-medium.cnf /etc/my.cnf && cd /usr/local/mysql/bin && chown -R mysql .; chgrp -R mysql .; chmod -R 744 scripts;  scripts/mysql_install_db --user=mysql; 

openssl:
	## install openssl
	cd ${srcdir} ; [ ! -e ${openssl}.tar.gz ] && wget http://www.openssl.org/source/${openssl}.tar.gz ; tar -zxvf ${openssl}.tar.gz && cd ${srcdir}${openssl} && ./config && make && make install 

php:
	## install php
	cd ${srcdir} ; [ ! -e ${php}.tar.gz ] && wget http://uk2.php.net/distributions/${php}.tar.gz ; tar -zxvf ${php}.tar.gz

	## get the apc sources into place and prepare 
	cd ${srcdir}; cd ${php}; wget http://pecl.php.net/get/APC-3.1.9.tgz; tar -zxvf APC-3.1.9.tgz && mv APC-3.1.9 ./ext/apc ; rm ./configure ; ./buildconf --force
	
	## compile php
	cd ${srcdir}; cd ${php}; ./configure --with-apxs2=/usr/local/apache2/bin/apxs --with-mysql=/usr/local/mysql  --enable-pdo --with-pdo-mysql=/usr/local/mysql --with-zlib-dir=../${zlib} --with-curl --enable-soap --with-openssl --with-apc && sudo make && sudo make install

	## install pecl extensions
	# note - this only works of the locate db is up to date. Run updatedb& first
extensions:
	updatedb && locate bbcode.so || pecl install bbcode 
	locate apc.so || printf "yes\n" | pecl install apc 

install:
	## move the apache configs into place
	cd ${srcdir}/${project} && cp httpd.conf /usr/local/apache2/conf/. && cp httpd-vhosts.conf /usr/local/apache2/conf/extra/. && cp ${project}.conf /usr/local/apache2/conf/extra/.

	## move php.ini into place
	cp ${srcdir}/${project}/php.ini /usr/local/lib/php.ini

	## set up a hosts file entry for ${project} virtual host
	echo "127.0.0.1 ${project}" >> /etc/hosts

	## copy the web and configuration folders into /export
	mkdir -p ${webroot}${project} && cd ${srcdir}/${project} 
	if [ -d ${webroot}${project}/www ] ; then rm -rf ${webroot}${project}/www; fi; cp -R htdocs ${webroot}${project}/www
	if [ -d /var/log/${project}] ; then touch /var/log/${project}/error.log; fi;
	## else mkdir -p /var/log/lampshade && touch /var/log/lampshade/error.log 

	## done
	echo "Installation completed - you can now start everything by running 'make start'"

start:
	## start mysql server 
	cd /usr/local/mysql && bin/mysqld_safe --user=mysql &  
	sleep 10
	
	## start apache
	/usr/local/apache2/bin/apachectl start

stop:
	## start mysql server 
	cd /usr/local/mysql && bin/mysqladmin shutdown
	sleep 10
	
	## start apache
	/usr/local/apache2/bin/apachectl stop

restart:
	## restart mysql server 
	/usr/local/mysql/bin/mysqladmin shutdown
	sleep 5
	cd /usr/local/mysql && bin/mysqld_safe --user=mysql &  
	sleep 10
	
	## restart apache
	/usr/local/apache2/bin/apachectl restart
