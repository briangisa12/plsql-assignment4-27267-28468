SET SERVEROUTPUT ON;

PROMPT  E1: Quantity zero (expect ORA-20001) 
DECLARE v_new_qty NUMBER;
BEGIN
    p_record_stock_movement(3, 'IN', 0, NULL, v_new_qty);
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/

PROMPT  E2: Invalid movement type (expect ORA-20002) 
DECLARE v_new_qty NUMBER;
BEGIN
    p_record_stock_movement(3, 'XYZ', 5, NULL, v_new_qty);
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/

PROMPT  E3: Product does not exist - NO_DATA_FOUND (expect ORA-20003) 
DECLARE v_new_qty NUMBER;
BEGIN
    p_record_stock_movement(999, 'IN', 5, NULL, v_new_qty);
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/

PROMPT  E4: Sell more than in stock (expect ORA-20004) 
DECLARE v_new_qty NUMBER;
BEGIN
    p_record_stock_movement(6, 'OUT', 50, NULL, v_new_qty);
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/


PROMPT ===== E5: Delete a supplier that does not exist - SQL%NOTFOUND (expect ORA-20005) =====
DECLARE v_rows NUMBER;
BEGIN
    p_delete_supplier(999, v_rows);
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/

PROMPT ===== E6: Delete a supplier that still has products - ORA-02292 (expect ORA-20006) =====
DECLARE v_rows NUMBER;
BEGIN
    p_delete_supplier(1, v_rows);
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/


PROMPT ===== E7: Product ID not found - NO_DATA_FOUND (expect ORA-20008) =====
DECLARE
    v_name VARCHAR2(100); v_supp VARCHAR2(100); v_value NUMBER; v_status VARCHAR2(20);
BEGIN
    p_get_product_details(999, v_name, v_supp, v_value, v_status);
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/

PROMPT ===== E8: Invalid product ID (expect ORA-20007) =====
DECLARE
    v_name VARCHAR2(100); v_supp VARCHAR2(100); v_value NUMBER; v_status VARCHAR2(20);
BEGIN
    p_get_product_details(-1, v_name, v_supp, v_value, v_status);
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/


PROMPT ===== E9: Report for a supplier that does not exist (expect ORA-20009) =====
DECLARE v_total NUMBER; v_low NUMBER;
BEGIN
    p_supplier_stock_report(999, v_total, v_low);
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/

PROMPT ===== E10: Report for a supplier with no products (expect ORA-20010) =====
DECLARE v_total NUMBER; v_low NUMBER;
BEGIN
    p_supplier_stock_report(4, v_total, v_low);
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/


PROMPT ===== E11: Bulk DML errors - FORALL SAVE EXCEPTIONS (STATIONERY -5000, Blue Pen would become negative) =====
DECLARE
    v_updated PLS_INTEGER;
    v_failed  PLS_INTEGER;
BEGIN
    p_bulk_price_adjust('STATIONERY', -5000, v_updated, v_failed);
    DBMS_OUTPUT.PUT_LINE('Updated: ' || v_updated || ' | Failed: ' || v_failed);
END;
/

PROMPT ===== E12: Invalid amount (expect ORA-20011) =====
DECLARE v_updated PLS_INTEGER; v_failed PLS_INTEGER;
BEGIN
    p_bulk_price_adjust('ELECTRONICS', 0, v_updated, v_failed);
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/

PROMPT ===== E13: Category with no products (expect ORA-20012) =====
DECLARE v_updated PLS_INTEGER; v_failed PLS_INTEGER;
BEGIN
    p_bulk_price_adjust('FURNITURE', 100, v_updated, v_failed);
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/


PROMPT ===== E14: Stock value of a missing product - NO_DATA_FOUND (expect ORA-20013) =====
BEGIN
    DBMS_OUTPUT.PUT_LINE(f_stock_value(999));
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/

PROMPT ===== E15: Product name used by two suppliers - TOO_MANY_ROWS (expect ORA-20015) =====
BEGIN
    DBMS_OUTPUT.PUT_LINE(f_find_product_id('USB Cable'));
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/

PROMPT ===== E16: Product name that does not exist (expect ORA-20014) =====
BEGIN
    DBMS_OUTPUT.PUT_LINE(f_find_product_id('Laptop'));
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/

PROMPT ===== E17: Unknown category (expect ORA-20016) =====
DECLARE
    v_low t_name_list;
BEGIN
    v_low := f_low_stock_products('FURNITURE');
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
END;
/

PROMPT ===== E18: Error is NOT hidden when the function is used in SQL (expect ORA-20013, not NULL) =====
SELECT f_stock_value(999) AS stock_value FROM dual;

PROMPT ===== E19: A failed movement leaves no partial changes - ROLLBACK check =====
DECLARE
    v_qty_before   products.qty_in_stock%TYPE;
    v_qty_after    products.qty_in_stock%TYPE;
    v_moves_before PLS_INTEGER;
    v_moves_after  PLS_INTEGER;
    v_new_qty      products.qty_in_stock%TYPE;
BEGIN
    SELECT qty_in_stock INTO v_qty_before FROM products WHERE product_id = 6;
    SELECT COUNT(*) INTO v_moves_before FROM stock_movements WHERE product_id = 6;

    BEGIN
        p_record_stock_movement(6, 'OUT', 50, 'Should fail', v_new_qty);
    EXCEPTION
        WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught: ' || SQLERRM);
    END;

    SELECT qty_in_stock INTO v_qty_after FROM products WHERE product_id = 6;
    SELECT COUNT(*) INTO v_moves_after FROM stock_movements WHERE product_id = 6;

    DBMS_OUTPUT.PUT_LINE('Stock before: ' || v_qty_before || ' | after: ' || v_qty_after);
    DBMS_OUTPUT.PUT_LINE('Movements before: ' || v_moves_before || ' | after: ' || v_moves_after);
    IF v_qty_before = v_qty_after AND v_moves_before = v_moves_after THEN
        DBMS_OUTPUT.PUT_LINE('PASS: nothing was changed by the failed call.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('FAIL: the failed call left partial changes.');
    END IF;
END;
/
