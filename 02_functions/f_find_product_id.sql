
CREATE OR REPLACE FUNCTION f_find_product_id (
    p_product_name IN products.product_name%TYPE,
    p_supplier_id  IN products.supplier_id%TYPE DEFAULT NULL
) RETURN products.product_id%TYPE
AS
    v_product_id products.product_id%TYPE;
BEGIN
    SELECT product_id
    INTO   v_product_id
    FROM   products
    WHERE  UPPER(product_name) = UPPER(TRIM(p_product_name))
    AND    (p_supplier_id IS NULL OR supplier_id = p_supplier_id);

    RETURN v_product_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20014, 'No product named "' || p_product_name || '"'
            || CASE WHEN p_supplier_id IS NOT NULL THEN ' for supplier ' || p_supplier_id END || '.');
    WHEN TOO_MANY_ROWS THEN
        RAISE_APPLICATION_ERROR(-20015, 'More than one product is named "' || p_product_name
            || '". Pass a supplier ID to choose one.');
END f_find_product_id;
/