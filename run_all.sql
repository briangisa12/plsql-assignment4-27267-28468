
SET SERVEROUTPUT ON

PROMPT ===== 1. Creating tables =====
@@00_schema/01_create_tables.sql

PROMPT ===== 2. Inserting sample data =====
@@00_schema/02_insert_sample_data.sql

PROMPT ===== 3. Compiling procedures =====
@@01_procedures/p_record_stock_movement.sql
@@01_procedures/p_delete_supplier.sql
@@01_procedures/p_get_product_details.sql
@@01_procedures/p_supplier_stock_report.sql
@@01_procedures/p_bulk_price_adjust.sql

PROMPT ===== 4. Compiling functions =====
@@02_functions/f_stock_value.sql
@@02_functions/f_find_product_id.sql
@@02_functions/f_low_stock_products.sql

PROMPT ===== 5. Checking all objects =====
SELECT object_type, object_name, status
FROM   user_objects
WHERE  object_type IN ('TABLE', 'TYPE', 'PROCEDURE', 'FUNCTION')
ORDER  BY object_type, object_name;

SELECT (SELECT COUNT(*) FROM suppliers)        AS suppliers,
       (SELECT COUNT(*) FROM products)         AS products,
       (SELECT COUNT(*) FROM stock_movements)  AS movements,
       (SELECT COUNT(*) FROM price_change_log) AS price_logs
FROM   dual;