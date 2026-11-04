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