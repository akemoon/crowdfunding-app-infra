#!/bin/bash

DBs=(
    "users"
    "projects"
    "payments"
    "promocodes"
)

echo "Creating databases: ${DBs[*]}"

for db in "${DBs[@]}"; do
  echo "Creating database '$db'..."
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    SELECT 'CREATE DATABASE $db'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$db')\gexec
EOSQL
done

echo "Done"
