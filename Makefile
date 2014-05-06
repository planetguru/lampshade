srcdir=/usr/src/
zlib=zlib-1.2.8.tar.gz
libxml2=libxml2-git-snapshot.tar.gz
m4=m4-latest.tar.gz
all:
	
	## on debian systems, install the follwoing first:
	# 
	#   sudo apt-get install cmake
	#   sudo apt-get install libncurses5-dev
	#   sudo apt-get install libxml2-dev
	#   sudo apt-get install autoconf
	
	## install zlib
	cd ${srcdir}; [ ! -e zlib-1.2.8.tar.gz ] && wget http://zlib.net/zlib-1.2.8.tar.gz ; tar -zxvf zlib-1.2.8.tar.gz; cd zlib-1.2.8/ && ./configure && make && make install

        ## install apache
	cd ${srcdir}; [ ! -e httpd-2.2.27.tar.gz ] && wget http://mirrors.ukfast.co.uk/sites/ftp.apache.org/httpd/httpd-2.2.27.tar.gz; tar -zxvf httpd-2.2.27.tar.gz; cd httpd-2.2.27 && ./configure --enable-so --enable-rewrite --enable-deflate --enable-expires --with-included-apr  && make && make install 

	## install curl
	#http://curl.haxx.se/download/curl-7.36.0.tar.gz
	cd ${sr#cdir} ; [ ! -e curl-7.36.0.tar.gz ] && wget http://curl.haxx.se/download/curl-7.36.0.tar.gz ; tar -zxvf curl-7.36.0.tar.gz && cd curl-7.36.0 && ./configure && make && make install

	## install libjpeg
	cd ${srcdir} ; [ ! -e jpegsrc.v7.tar.gz ] && wget http://www.ijg.org/files/jpegsrc.v7.tar.gz ; tar -zxvf jpegsrc.v7.tar.gz && cd jpeg-7 && ./configure &&  make && make install && make install-libLTLIBRARIES

	## copy shared object into a place where php's configure can find it
	if [ -f /usr/lib/libjpeg.so ] ; then echo "libjpeg.so already in place."; else echo "Copying new libjpeg shared object into /usr/lib/libjpeg.so"; cp  /usr/local/lib/libjpeg.so.7.0.0 /usr/lib/libjpeg.so; fi

	## install gd libs
	cd ${srcdir} ; [ ! -e libgd-2.1.0.tar.gz ] && wget https://bitbucket.org/libgd/gd-libgd/downloads/libgd-2.1.0.tar.gz ; tar -zxvf libgd-2.1.0.tar.gz && cd libgd-2.1.0 && ./configure --with-jpeg=/usr/local && make && make install

	## build the mysql server and client libs
	useradd mysql;  cd ${srcdir}; [ ! -e mysql-5.6.17.tar.gz ] && wget http://cdn.mysql.com/Downloads/MySQL-5.6/mysql-5.6.17.tar.gz ; tar -zxvf mysql-5.6.17.tar.gz && cd ${srcdir}mysql-5.6.17 && cmake .; make; make install; cd /usr/local/mysql; chown -R mysql .; chgrp -R mysql .; scripts/mysql_install_db --user=mysql; chown -R root .; chown -R mysql data; 

#./configure --prefix=/usr/local/mysql && make && make install && cp support-files/my-medium.cnf /etc/my.cnf && cd /usr/local/mysql && chown -R mysql .; chgrp -R mysql .; bin/mysql_install_db --user=mysql; chown -R root .; chown -R root .; chown -R mysql var

	## install openssl
	cd ${srcdir} ; [ ! -e openssl-1.0.1g.tar.gz ] && wget http://www.openssl.org/source/openssl-1.0.1g.tar.gz --no-check-certificate; tar -zxvf openssl-1.0.1g.tar.gz && cd ${srcdir}openssl-1.0.1g && ./config -fPIC && make && make install 

	## install php
	# http://uk1.php.net/distributions/php-5.5.10.tar.gz
	cd ${srcdir} ; [ ! -e php-5.5.10.tar.gz ] && wget http://uk1.php.net/distributions/php-5.5.10.tar.gz; tar -zxvf php-5.5.10.tar.gz && cd php-5.5.10 && ./configure --with-apxs2=/usr/local/apache2/bin/apxs --with-mysql=/usr/local/mysql  --enable-pdo --with-pdo-mysql=shared,/usr/local/mysql --with-zlib-dir=../zlib-1.2.8 --with-jpeg-dir=/usr/lib --with-curl --enable-soap --with-openssl && sudo make && sudo make install

	## install pecl extensions
	# PATH=$PATH:/usr/local/apache2/bin:/usr/local/bin && pecl install apc
	#pecl install pdo && pecl install bbcode && pecl install xdebug
	pecl install bbcode-1.0.3b1
	# && pecl install xdebug

	## install apc from source 
	#cd ${srcdir} &&  svn checkout http://svn.php.net/repository/pecl/apc/trunk && cd ${srcdir}/trunk && phpize && ./configure && make && make install


install:
	# stop mysql server if it is already running
	-/usr/local/mysql/bin/mysqladmin shutdown
	sleep 5

	## start mysql server before trying to build the database
	cd /usr/local/mysql && bin/mysqld_safe --user=mysql &  
	sleep 10
	
	## set up the torkalot database
	-cd ${srcdir}/torkalot && /usr/local/mysql/bin/mysql < installdb.sh

	## close the database now
	-cd /usr/local/mysql && bin/mysqladmin shutdown

	## set up the log files
	mkdir -p /var/log/torkalot
	mkdir -p /var/log/apache
	touch /var/log/apache/rewrite.log

	## move the apache configs into place
#	cd ${srcdir}/torkalot && cp httpd.conf /usr/local/apache2/conf/. && cp httpd-vhosts.conf /usr/local/apache2/conf/extra/. && cp torkalot.conf /usr/local/apache2/conf/extra/.

	## move php.ini into place
	cp ${srcdir}/torkalot/php.ini /usr/local/lib/php.ini

	## set up a hosts file entry for the torkalot virtual host
	echo "127.0.0.1 torkalot" >> /etc/hosts

	## copy the web and configuration folders into /export
	mkdir -p /export/torkalot && cd ${srcdir}/torkalot 
	cp -R htdocs /export/torkalot/www
	cp -R htlibs /export/torkalot/etc

	## done
	echo "Installation completed - you can now start everything by running 'make start'"

website:
	## move the apache configs into place
	cd ${srcdir}/torkalot && cp torkalot.conf /usr/local/apache2/conf/extra/.

	## copy the web and configuration folders into /export
	mkdir -p /export/torkalot && cd ${srcdir}/torkalot 
	if [ -d /export/torkalot/www ] ; then rm -rf /export/torkalot/www; fi; cp -R htdocs /export/torkalot/www
	if [ -d /export/torkalot/etc ] ; then rm -rf /export/torkalot/etc; fi; cp -R htlibs /export/torkalot/etc

	## done
	echo "Web directories, apache configurations and torkalot configurations are now in place"

start:
	## start mysql server 
	cd /usr/local/mysql && bin/mysqld_safe --user=mysql &  
	sleep 10
	
	## start apache
	/usr/local/apache2/bin/apachectl start

restart:
	## restart mysql server 
	/usr/local/mysql/bin/mysqladmin shutdown
	sleep 5
	cd /usr/local/mysql && bin/mysqld_safe --user=mysql &  
	sleep 10
	
	## restart apache
	/usr/local/apache2/bin/apachectl restart
