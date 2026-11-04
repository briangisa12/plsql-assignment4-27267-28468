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