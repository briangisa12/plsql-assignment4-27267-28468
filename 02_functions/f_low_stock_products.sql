
CREATE OR REPLACE TYPE t_name_list AS TABLE OF VARCHAR2(200);
/

CREATE OR REPLACE FUNCTION f_low_stock_products (
    p_category IN products.category%TYPE DEFAULT NULL
) RETURN t_name_list
AS
    v_names         t_name_list;
    v_category_rows PLS_INTEGER;
    e_unknown_category EXCEPTION;
BEGIN
    IF p_category IS NOT NULL THEN
        SELECT COUNT(*)
        INTO   v_category_rows
        FROM   products
        WHERE  UPPER(category) = UPPER(TRIM(p_category));

        IF v_category_rows = 0 THEN
            RAISE e_unknown_category;
        END IF;
    END IF;

    SELECT product_name || ' (qty ' || qty_in_stock || ', reorder at ' || reorder_level || ')'
    BULK COLLECT INTO v_names
    FROM   products
    WHERE  qty_in_stock < reorder_level
    AND    (p_category IS NULL OR UPPER(category) = UPPER(TRIM(p_category)))
    ORDER  BY product_name;

    RETURN v_names;
EXCEPTION
    WHEN e_unknown_category THEN
        RAISE_APPLICATION_ERROR(-20016, 'Category "' || p_category || '" does not exist.');
END f_low_stock_products;
/