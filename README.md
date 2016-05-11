# SLKDOL

This is a rails app to assist the data entry of payroll information when you  
find yourself in the middle of a CA Dept of Labor audit.

Current data structures are based of the AGPAY payroll system

ssh -i ~/.ssh/keys/aws-ore.pem -C ubuntu@assurehire.com "/usr/local/pgsql/bin/pg_dump -C -hlocalhost -Upostgres --no-owner --no-privileges slkdol" | psql slkdol

### Payroll Calendar Years

2013: 2012-12-31  2013-12-29
2014: 2013-12-30  2014-12-28

### Inserting a year from agpay

insert into time_entries(employee_id,day,ssn,name,rate,pieces,hours,amount,weeknum) select employee_id,day,ssn,name,rate,pieces,hours,amount,EXTRACT(WEEK FROM day) from agpay where day >= '2012-12-31' and day <= '2013-12-29';
