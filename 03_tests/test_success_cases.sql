SET SERVEROUTPUT ON;

PROMPT ===== S1: Stock IN - 20 Wireless Mouse (product 3) =====
DECLARE
    v_new_qty products.qty_in_stock%TYPE;
BEGIN
    p_record_stock_movement(3, 'IN', 20, 'Restock from supplier', v_new_qty);
    DBMS_OUTPUT.PUT_LINE('New quantity for product 3: ' || v_new_qty);
END;
/

PROMPT ===== S2: Stock OUT - 10 A4 Paper Ream (product 5) =====
DECLARE
    v_new_qty products.qty_in_stock%TYPE;
BEGIN
    p_record_stock_movement(5, 'OUT', 10, 'Sold to AUCA library', v_new_qty);
    DBMS_OUTPUT.PUT_LINE('New quantity for product 5: ' || v_new_qty);
END;
/


PROMPT ===== S3: Delete a supplier that has no products =====
DECLARE
    v_supplier_id  suppliers.supplier_id%TYPE;
    v_rows_deleted NUMBER;
BEGIN
    INSERT INTO suppliers (supplier_name, phone, email)
    VALUES ('Temporary Supplier Ltd', '0788999999', 'temp@supplier.rw')
    RETURNING supplier_id INTO v_supplier_id;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Created temporary supplier ' || v_supplier_id);

    p_delete_supplier(v_supplier_id, v_rows_deleted);
    DBMS_OUTPUT.PUT_LINE('Rows deleted: ' || v_rows_deleted);
END;
/


PROMPT ===== S4: Product details using %ROWTYPE records (product 6 - Blue Pen) =====
DECLARE
    v_name   products.product_name%TYPE;
    v_supp   suppliers.supplier_name%TYPE;
    v_value  NUMBER;
    v_status VARCHAR2(20);
BEGIN
    p_get_product_details(6, v_name, v_supp, v_value, v_status);
    DBMS_OUTPUT.PUT_LINE('Product     : ' || v_name);
    DBMS_OUTPUT.PUT_LINE('Supplier    : ' || v_supp);
    DBMS_OUTPUT.PUT_LINE('Stock value : ' || v_value || ' RWF');
    DBMS_OUTPUT.PUT_LINE('Status      : ' || v_status);
END;
/


PROMPT ===== S5: Supplier stock report - explicit cursors, user-defined record, VARRAY (supplier 2) =====
DECLARE
    v_total NUMBER;
    v_low   NUMBER;
BEGIN
    p_supplier_stock_report(2, v_total, v_low);
    DBMS_OUTPUT.PUT_LINE('Returned OUT values -> total value: ' || v_total
                         || ' RWF, low-stock products: ' || v_low);
END;
/


PROMPT ===== S6: Bulk price increase - BULK COLLECT + FORALL (ELECTRONICS +500) =====
DECLARE
    v_updated PLS_INTEGER;
    v_failed  PLS_INTEGER;
BEGIN
    p_bulk_price_adjust('ELECTRONICS', 500, v_updated, v_failed);
    DBMS_OUTPUT.PUT_LINE('Updated: ' || v_updated || ' | Failed: ' || v_failed);
END;
/

PROMPT ===== Price change log after S6 =====
SELECT l.log_id, p.product_name, l.old_price, l.new_price
FROM   price_change_log l
JOIN   products p ON p.product_id = l.product_id
ORDER  BY l.log_id;



PROMPT ===== S7: Functions called from an anonymous PL/SQL block =====
DECLARE
    v_low t_name_list;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Stock value of product 6      : ' || f_stock_value(6) || ' RWF');
    DBMS_OUTPUT.PUT_LINE('ID of "Keyboard"              : ' || f_find_product_id('Keyboard'));
    DBMS_OUTPUT.PUT_LINE('ID of "USB Cable" supplier 3  : ' || f_find_product_id('USB Cable', 3));

    v_low := f_low_stock_products;
    DBMS_OUTPUT.PUT_LINE('Low-stock products: ' || v_low.COUNT);
    FOR i IN 1 .. v_low.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('  - ' || v_low(i));
    END LOOP;
END;
/

PROMPT ===== S8: Function called from a SQL SELECT statement =====
SELECT product_id, product_name, f_stock_value(product_id) AS stock_value
FROM   products
ORDER  BY product_id;

PROMPT ===== S9: Function returning a nested table, used with TABLE() in SQL =====
SELECT column_value AS low_stock_product
FROM   TABLE(f_low_stock_products('STATIONERY'));