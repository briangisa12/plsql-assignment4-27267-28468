-- =============================================================
-- Procedure : p_record_stock_movement
-- Purpose   : Record a stock IN (delivery) or OUT (sale), update
--             the product quantity and log the movement.
-- Shows     : implicit cursors (UPDATE/INSERT) with SQL%ROWCOUNT
--             and SQL%FOUND, IN/OUT parameters, NO_DATA_FOUND,
--             user-defined exceptions, RAISE_APPLICATION_ERROR.
-- Errors    : -20001 invalid quantity, -20002 invalid type,
--             -20003 product not found, -20004 not enough stock
-- =============================================================
CREATE OR REPLACE PROCEDURE p_record_stock_movement (
    p_product_id    IN  products.product_id%TYPE,
    p_movement_type IN  stock_movements.movement_type%TYPE,
    p_quantity      IN  stock_movements.quantity%TYPE,
    p_note          IN  stock_movements.note%TYPE,
    p_new_qty       OUT products.qty_in_stock%TYPE
) AS
    -- User-defined exceptions
    e_invalid_quantity   EXCEPTION;
    e_invalid_type       EXCEPTION;
    e_insufficient_stock EXCEPTION;

    v_type        stock_movements.movement_type%TYPE;
    v_current_qty products.qty_in_stock%TYPE;
    v_change      NUMBER;
BEGIN
    -- 1. Validate the inputs
    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        RAISE e_invalid_quantity;
    END IF;

    IF p_movement_type IS NULL OR UPPER(TRIM(p_movement_type)) NOT IN ('IN', 'OUT') THEN
        RAISE e_invalid_type;
    END IF;
    v_type := UPPER(TRIM(p_movement_type));

    -- 2. Read the current stock and lock the row.
    --    If the product does not exist, Oracle raises NO_DATA_FOUND.
    SELECT qty_in_stock
    INTO   v_current_qty
    FROM   products
    WHERE  product_id = p_product_id
    FOR UPDATE;

    -- 3. Business rule: you cannot sell more than you have
    IF v_type = 'OUT' AND p_quantity > v_current_qty THEN
        RAISE e_insufficient_stock;
    END IF;

    v_change := CASE v_type WHEN 'IN' THEN p_quantity ELSE -p_quantity END;

    -- 4. Implicit cursor: UPDATE
    UPDATE products
    SET    qty_in_stock = qty_in_stock + v_change
    WHERE  product_id = p_product_id
    RETURNING qty_in_stock INTO p_new_qty;

    DBMS_OUTPUT.PUT_LINE('UPDATE affected ' || SQL%ROWCOUNT || ' row(s) in PRODUCTS.');

    -- 5. Implicit cursor: INSERT
    INSERT INTO stock_movements (product_id, movement_type, quantity, note)
    VALUES (p_product_id, v_type, p_quantity, p_note);

    IF SQL%FOUND THEN
        DBMS_OUTPUT.PUT_LINE('INSERT recorded ' || SQL%ROWCOUNT || ' row(s) in STOCK_MOVEMENTS.');
    END IF;

    COMMIT;

EXCEPTION
    WHEN e_invalid_quantity THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'Quantity must be a positive number. Given: '
                                        || NVL(TO_CHAR(p_quantity), 'NULL'));
    WHEN e_invalid_type THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, 'Movement type must be IN or OUT. Given: '
                                        || NVL(p_movement_type, 'NULL'));
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'Product ' || p_product_id || ' does not exist.');
    WHEN e_insufficient_stock THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, 'Not enough stock for product ' || p_product_id
                                        || '. Available: ' || v_current_qty
                                        || ', requested: ' || p_quantity || '.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;   -- never hide unexpected errors
END p_record_stock_movement;
/
