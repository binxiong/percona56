#!/bin/bash
set -e

VOLUME_HOME="/data/mysql"

# if command starts with an option, prepend mysqld
if [ "${1:0:1}" = '-' ]; then
	set -- mysqld_safe "$@"
fi

if [ "$1" = 'mysqld_safe' ]; then
    if [[ ! -d $VOLUME_HOME/mysql ]]; then
        echo "=> An empty or uninitialized MySQL volume is detected in $VOLUME_HOME"
        echo "=> Installing MySQL ..."
	mysql_install_db --user=mysql --rpm --keep-my-cnf
	echo "=> Finished mysql_install_db"
        mysqld --user=mysql --skip-networking &
        pid="$!"
    
        mysql=( mysql --protocol=socket -uroot )
    
        for i in {30..0}; do
    	if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
     	    break
    	fi
    	echo 'MySQL init process in progress...'
            sleep 1
        done
        if [ "$i" = 0 ]; then
    	echo >&2 'MySQL init process failed.'
    	    exit 1
        fi
    
        # sed is for https://bugs.mysql.com/bug.php?id=20545
        #mysql_tzinfo_to_sql /usr/share/zoneinfo | "${mysql[@]}" mysql
        ####mysql_tzinfo_to_sql /usr/share/zoneinfo ###| sed 's/Local time zone must be set--see zic manual page/FCTY/' | "${mysql[@]}" mysql
    
    	#echo "SET @@SESSION.SQL_LOG_BIN=0; DELETE FROM mysql.user; CREATE USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'; GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION ; FLUSH PRIVILEGES ;" | "${mysql[@]}"
        mysqladmin password "${MYSQL_ROOT_PASSWORD}"
        mysql+=( -p"${MYSQL_ROOT_PASSWORD}" )
    
        if [ "$MYSQL_DATABASE" ]; then
    	echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` ;" | "${mysql[@]}"
    	    mysql+=( "$MYSQL_DATABASE" )
        fi
    
        if [ "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]; then
    	echo "CREATE USER '"$MYSQL_USER"'@'%' IDENTIFIED BY '"$MYSQL_PASSWORD"' ;" | "${mysql[@]}"
    
    	if [ "$MYSQL_DATABASE" ]; then
    	    echo "GRANT ALL ON \`"$MYSQL_DATABASE"\`.* TO '"$MYSQL_USER"'@'%' ;" | "${mysql[@]}"
    	fi
    
    	echo 'FLUSH PRIVILEGES ;' | "${mysql[@]}"
        fi
    
        echo
        for f in /docker-entrypoint-initdb.d/*; do
    	case "$f" in
    	   *.sh)  echo "$0: running $f"; . "$f" ;;
    	   *.sql) echo "$0: running $f"; "${mysql[@]}" < "$f" && echo ;;
    	   *)     echo "$0: ignoring $f" ;;
    	esac
    	echo
        done
    
        if ! kill -s TERM "$pid" || ! wait "$pid"; then
    	echo >&2 "=> MySQL init process failed."
    	exit 1
        fi
    
        echo
        echo "=> MySQL init process done. Ready for start up."
        echo
    fi
fi

exec "$@"
