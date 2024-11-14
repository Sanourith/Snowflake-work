# Training with Snowflake

# Data Loading
We have the following schema:

![img](./images/schema_partie6%20snowflake.png)

The first step is to create the various tables and populate them from the S3 bucket: s3.

Then, write all the queries for implementing and populating these tables in a file named ***_init.sql_***.

# Star Schema Creation
Next, transform the normalized data from the previous step into a star schema. Here, the goal will be to analyze the _tracks_ available on CDs.

Then, create the tables for the proposed star schema in a file named ***_star.sql_***.

# Queries
Finally, in a file named query.sql, write the queries that answer the following questions:

1. What are the titles of the albums that have more than 1 CD?
2. What are the tracks produced in 2000 or 2002?
3. What are the names and composers of Rock and Jazz tracks?
4. What are the 10 longest albums?
5. What is the number of albums produced by each artist?
6. What is the number of tracks produced by each artist?
7. What is the most popular music genre in the 2000s?
8. What are the names of all playlists that feature tracks longer than 4 minutes?
9. What are the Rock tracks whose artists are based in France?
10. What is the average track size by music genre?
11. What are the playlists that feature tracks by artists born before 1990?

The purpose of the queries is to collect the results in a document named ***_answer.txt_***.
