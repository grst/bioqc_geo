#!/bin/bash 


# first retrieve the database schema: 
sqlite3 GEOmetadb.sqlite .schema > geometadb_schema.sql 

# export the tables 
mkdir -p tables
for table in $(cat tables.txt); do 
    sqlite3 GEOmetadb.sqlite -header -csv -separator ',' "select * from ${table};" > tables/${table}.csv;
done

# remove invalid utf8 characters
for file in tables/*.csv; do 
    iconv -c -f utf-8 -t utf-8 $file > $file.utf8.csv; 
done 


