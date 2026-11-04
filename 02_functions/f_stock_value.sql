
CREATE OR REPLACE FUNCTION f_stock_value (
    p_product_id IN products.product_id%TYPE
) RETURN NUMBER
AS
    v_qty   products.qty_in_stock%TYPE;
    v_price products.unit_price%TYPE;
BEGIN
    SELECT qty_in_stock, unit_price
    INTO   v_qty, v_price
    FROM   products
    WHERE  product_id = p_product_id;

    RETURN v_qty * v_price;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Called from SQL, an unhandled NO_DATA_FOUND would silently return NULL.
        -- Raising our own error makes the problem visible instead.
        RAISE_APPLICATION_ERROR(-20013, 'Product ' || p_product_id
                                        || ' does not exist. Stock value cannot be calculated.');
END f_stock_value;
/