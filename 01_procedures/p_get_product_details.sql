
CREATE OR REPLACE PROCEDURE p_get_product_details (
    p_product_id    IN  products.product_id%TYPE,
    p_product_name  OUT products.product_name%TYPE,
    p_supplier_name OUT suppliers.supplier_name%TYPE,
    p_stock_value   OUT NUMBER,
    p_stock_status  OUT VARCHAR2
) AS
    
    v_product    products%ROWTYPE;
    v_supplier   suppliers%ROWTYPE;

    e_invalid_id EXCEPTION;
BEGIN
    IF p_product_id IS NULL OR p_product_id <= 0 THEN
        RAISE e_invalid_id;
    END IF;

    
    SELECT *
    INTO   v_product
    FROM   products
    WHERE  product_id = p_product_id;

   
    SELECT *
    INTO   v_supplier
    FROM   suppliers
    WHERE  supplier_id = v_product.supplier_id;

    -- Process the record fields
    p_product_name  := v_product.product_name;
    p_supplier_name := v_supplier.supplier_name;
    p_stock_value   := v_product.qty_in_stock * v_product.unit_price;
    p_stock_status  := CASE
                           WHEN v_product.qty_in_stock = 0 THEN 'OUT OF STOCK'
                           WHEN v_product.qty_in_stock < v_product.reorder_level THEN 'REORDER NEEDED'
                           ELSE 'OK'
                       END;

    DBMS_OUTPUT.PUT_LINE('Record loaded: ' || v_product.product_name
                         || ' | category '      || v_product.category
                         || ' | price '         || v_product.unit_price
                         || ' | qty '           || v_product.qty_in_stock
                         || ' | reorder level ' || v_product.reorder_level);
EXCEPTION
    WHEN e_invalid_id THEN
        RAISE_APPLICATION_ERROR(-20007, 'Product ID must be a positive number. Given: '
                                        || NVL(TO_CHAR(p_product_id), 'NULL'));
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20008, 'No product found with ID ' || p_product_id || '.');
    WHEN OTHERS THEN
        RAISE;   -- never hide unexpected errors
END p_get_product_details;
/