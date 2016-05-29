#!/bin/bash
#######################################################
## Author:	Andrew Martin <amartin@avidandrew.com>
## Date:	4/3/16
## Descr:	Backs up the gogs MySQL database
## Depend:	mysqldump
#######################################################
BACKUP_DIR="{{ gogs_backup }}"
BACKUP_KEEPTIME={{ gogs_backup_keeptime }}

/usr/bin/mysqldump -u root {{ gogs_db_name }} > ${BACKUP_DIR}/$(date +%Y_%m_%d).sql
find ${BACKUP_DIR} -mtime +${BACKUP_KEEPTIME} -exec rm {} \;
