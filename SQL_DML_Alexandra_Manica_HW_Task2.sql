-- Task 2

-- Task 2.1.
-- Create table ‘table_to_delete’ and fill it with the following query:

CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x;

--Additional details: 
-- Execution time - around 45s

-- Task 2.2
-- Lookup how much space this table consumes with the following query:
SELECT *, pg_size_pretty(total_bytes) AS total,
                                    pg_size_pretty(index_bytes) AS INDEX,
                                    pg_size_pretty(toast_bytes) AS toast,
                                    pg_size_pretty(table_bytes) AS TABLE
               FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
                               FROM (SELECT c.oid,nspname AS table_schema,
                                                               relname AS TABLE_NAME,
                                                              c.reltuples AS row_estimate,
                                                              pg_total_relation_size(c.oid) AS total_bytes,
                                                              pg_indexes_size(c.oid) AS index_bytes,
                                                              pg_total_relation_size(reltoastrelid) AS toast_bytes
                                              FROM pg_class c
                                              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                                              WHERE relkind = 'r'
                                              ) a
                                    ) a
               WHERE table_name LIKE '%table_to_delete%';
               
 --Execution time - under 1s
-- Storage: The table table_to_delete consumes approximately 575 MB of storage.
-- It has no indexes and negligible TOAST usage (~8 KB).
-- TOAST is PostgreSQL’s storage mechanism for oversized values stored outside the main table.
-- Since TOAST usage is minimal, the storage is almost entirely regular table data.
-- Dropping this table would free about 602,521,600 bytes (~575 MB).
               
 -- Task 2.3. 
--Issue the following DELETE operation on ‘table_to_delete’:
--
-- DELETE FROM table_to_delete
-- WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0; -- removes 1/3 of all rows
--
-- a) Note how much time it takes to perform this DELETE statement;
-- b) Lookup how much space this table consumes after previous DELETE;
-- c) Perform the following command (if you're using DBeaver, press Ctrl+Shift+O to observe server output (VACUUM results)): VACUUM FULL VERBOSE table_to_delete;
-- d) Check space consumption of the table once again and make conclusions;
-- e) Recreate ‘table_to_delete’ table;

DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0;

-- a) Execution time - aprox 30s
-- b) Storage: After reruning the query from 2.2, the table table_to_delete consumes approximately 575 MB of storage

VACUUM FULL VERBOSE table_to_delete;
-- c + d) Execution time: around 10s
-- Storage: After reruning the query from 2.2, the table table_to_delete consumes approximately 383 MB of storage

--e)
DROP TABLE table_to_delete;

CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x;

-- Task 2.4
-- Issue the following TRUNCATE operation: TRUNCATE table_to_delete;
-- a) Note how much time it takes to perform this TRUNCATE statement.
-- b) Compare with previous results and make conclusion.
-- c) Check space consumption of the table once again and make conclusions;

TRUNCATE table_to_delete;

-- a) Execution time: around 1s (almost instantly)
---- b) Comparing the results from performing truncate vs delete or vacuum full,
-- we can see that truncate is the fastest one, the operation being executed almost instantly.
-- c) Storage: After reruning the query from 2.2, the table table_to_delete consumes approximately 0 MB of storage.


-- Task 2.5 Comparision
--  2.5. a) Space consumption of ‘table_to_delete’ table before and after each operation; -- mentioned for each point

-- 	2.5 b) Compare DELETE and TRUNCATE in terms of:
--execution time
--disk space usage
--transaction behavior
--rollback possibility

-- DELETE:
-- slower, because it perfoms the operation row by row (aprox 30s)
-- does NOT free disk space immediately
-- transactional
-- rollback possible

-- TRUNCATE:
-- very fast (aprox 1s)
-- frees disk space immediately
-- transactional in PostgreSQL
-- rollback possible

-- c)How these operations affect performance and storage?

-- c.1.) Why DELETE does not free space:
-- When deleting a row, PostgreSQL does NOT physically remove it.
-- Instead it marks the row as a dead tuple (the row becomes invisible to new transactions) but still physically present on disk.

-- c.2) Why VACUUM FULL reduces size:
-- VACUUM FULL creates a copy of the table from which the dead tuples are removed.
-- Old table file is deleted and space is returned to the OS, that's why the the size is reduced.

-- c.3) Why TRUNCATE behaves differently:
-- TRUNCATE does not delete rows one by one.
-- Instead it drops the entire data file (the pshycal file on the OS where the data it's stored) and creates a new empty one.

-- c.4) Impact on performance/storage:

-- DELETE:
-- Precise — targets specific rows with WHERE clause
-- Slow on large tables due to row by row processing
-- Dead tuples are kept on disk and VACUUM is required afterwards to mark dead space as reusable.
-- After performing a delete operation. the table size doesn't change.

-- TRUNCATE:
-- Extremely fast regardless of table size
-- Frees disk space immediately — no dead tuples created
-- Cannot filter rows — removes all data from the table
-- Requires full table lock — blocks all reads and writes

-- VACUUM FULL:
-- Rewrites entire table — reduces file size and returns space to OS
-- Removes all dead tuples
-- Requires full table lock — no reads or writes during operation
-- Very slow on large tables due to full data rewrite
