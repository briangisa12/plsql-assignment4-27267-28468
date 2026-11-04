SET SERVEROUTPUT ON;

PROMPT S1: Stock IN - 20 Wireless Mouse (product 3) 
DECLARE
    v_new_qty products.qty_in_stock%TYPE;
BEGIN
    p_record_stock_movement(3, 'IN', 20, 'Restock from supplier', v_new_qty);
    DBMS_OUTPUT.PUT_LINE('New quantity for product 3: ' || v_new_qty);
END;
/

PROMPT S2: Stock OUT - 10 A4 Paper Ream (product 5) 
DECLARE
    v_new_qty products.qty_in_stock%TYPE;
BEGIN
    p_record_stock_movement(5, 'OUT', 10, 'Sold to AUCA library', v_new_qty);
    DBMS_OUTPUT.PUT_LINE('New quantity for product 5: ' || v_new_qty);
END;
/