CREATE EXTERNAL TABLE IF NOT EXISTS test_db.test_table1 (
  id INT,
  first_name STRING,
  last_name STRING,
  email STRING,
  gender STRING,
  is_active BOOLEAN,
  joined_date STRING)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 's3a://athena-test/data/'
TBLPROPERTIES ('skip.header.line.count'='1')
