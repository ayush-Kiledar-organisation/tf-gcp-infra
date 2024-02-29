#!/bin/bash

cat << EOF > /opt/csye6225/webapp/.env
host=${google_sql_database_instance.db_instance.private_ip_address}
username=${google_sql_user.db_user.name}
password=${random_password.password.result}
database=${google_sql_database.database.name}
EOF