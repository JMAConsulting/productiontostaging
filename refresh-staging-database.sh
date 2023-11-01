#!/bin/sh
# 1. WordPress script, using combination of mysql, wp-cli, cv and other commands
#     First create a backup of the current staging database, 
#     backup the prod database
#     take site instance offline by putting in maintenance mode
#     and then replace contents of staging database with contents of production db.
#     The name of the staging database will not change, neither will the settings file
#     Search and replace URLs in Mosaico: cv api MosaicoTemplate.replaceurls from_url="https://stagingsite" to_url="https://productionsite"
#     Search and replace URLs in WordPress (example in gist above)
#     Update the live payment processor to blank out the username and password, replacing it with "TEST". Use cv sql for this.
#     Set environment to staging. Use cv api for this.
#     Redirect outbound emails to database. Use cv sql for this.
#     what about diff of code between prod and staging? I think we need to retain staging, but there may be things in code that affect metadata, etc. Should we run a CiviCRM update so that any extension updates get run to change the database appropriately?

# 2. Drupal
#     backup db of the current staging database
#     backup db of the current prod database
#     take staging instance offline by putting into maintenance mode
#     restore current prod database contents into current staging database

#Wordpress scripts 
#1. first backup current staging database 
mysqldump staging-databasename > ~/stagingbackups/staging-databasename.sql
#2. backup production database
mysqldump production-databasename > ~/productionbackups/production-databasename.sql
#3. take site instance offline
wp maintenance-mode activate
#4. replace content of staging database with contents of production db
mysql
use staging-databasename;
source /productionbackups/production-databasename.sql
#5. search and replace URLs in Mosaico
cv api MosaicoTemplate.replaceurls from_url="https://stagingsite" to_url="https://productionsite"
#6. search and replace URLs in wordpress
cd htdocs
wp search-replace --url='https://stagingsite' 'stagingsite' 'productionsite' --all-tables-with-prefix
#7. update the live payment processor to blank out the username and password
echo "UPDATE `civicrm_payment_processor` SET `user_name`='TEST',`password`='TEST' where `is_active`=1 and `is_test`=0;" | cv sql:cli 
#8. set environment to staging
wp cv api Setting.create environment="Staging"
#9. redirect outbound emails to database.
echo "INSERT INTO civicrm_setting(name, value, domain_id, contact_id, is_domain, component_id) VALUE ('mailing_backend', 'xxxxxxx', 1, null, 1, null)" | cv sql:cli

#Drupal scripts
#1. backup db of the current staging database
mysqldump staging-databasename > ~/stagingbackups/staging-databasename.sql
#2. backup db of the current production database
mysqldump production-databasename > ~/productionbackups/production-databasename.sql
#3. take the staging instance offiline by putting into maintenance mode
wp maintenance-mode activate
#4. restore current production database contents into current staging database
mysql
use staging-databasename;
source /productionbackups/production-databasename.sql