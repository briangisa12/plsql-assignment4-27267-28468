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