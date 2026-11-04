
CREATE OR REPLACE PROCEDURE p_supplier_stock_report (
    p_supplier_id     IN  suppliers.supplier_id%TYPE,
    p_total_value     OUT NUMBER,
    p_low_stock_count OUT NUMBER
) AS
    
    TYPE t_report_line IS RECORD (
        product_name products.product_name%TYPE,
        qty          products.qty_in_stock%TYPE,
        unit_price   products.unit_price%TYPE,
        line_value   NUMBER,
        status       VARCHAR2(10)
    );
    v_line t_report_line;

    
    TYPE t_category_list IS VARRAY(10) OF products.category%TYPE;
    v_categories t_category_list := t_category_list();
    v_already_listed BOOLEAN;

   
    CURSOR c_products (cp_supplier_id suppliers.supplier_id%TYPE) IS
        SELECT product_name, category, qty_in_stock, unit_price, reorder_level
        FROM   products
        WHERE  supplier_id = cp_supplier_id
        ORDER  BY product_name;
    v_product c_products%ROWTYPE;

    
    CURSOR c_movements (cp_supplier_id suppliers.supplier_id%TYPE) IS
        SELECT m.movement_date, p.product_name, m.movement_type, m.quantity
        FROM   stock_movements m
        JOIN   products p ON p.product_id = m.product_id
        WHERE  p.supplier_id = cp_supplier_id
        ORDER  BY m.movement_id;

    v_supplier_name  suppliers.supplier_name%TYPE;
    v_product_count  PLS_INTEGER := 0;
    v_movement_count PLS_INTEGER := 0;
    e_no_products    EXCEPTION;
BEGIN
    
    SELECT supplier_name
    INTO   v_supplier_name
    FROM   suppliers
    WHERE  supplier_id = p_supplier_id;

    p_total_value     := 0;
    p_low_stock_count := 0;

    DBMS_OUTPUT.PUT_LINE('STOCK REPORT - ' || v_supplier_name);
    DBMS_OUTPUT.PUT_LINE(RPAD('Product', 18) || LPAD('Qty', 6) || LPAD('Price', 10)
                         || LPAD('Value', 12) || '  Status');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 56, '-'));

   
    OPEN c_products(p_supplier_id);
    LOOP
        FETCH c_products INTO v_product;
        EXIT WHEN c_products%NOTFOUND;

        -- Fill the user-defined record
        v_line.product_name := v_product.product_name;
        v_line.qty          := v_product.qty_in_stock;
        v_line.unit_price   := v_product.unit_price;
        v_line.line_value   := v_product.qty_in_stock * v_product.unit_price;
        v_line.status       := CASE WHEN v_product.qty_in_stock < v_product.reorder_level
                                    THEN 'REORDER' ELSE 'OK' END;

        p_total_value := p_total_value + v_line.line_value;
        IF v_line.status = 'REORDER' THEN
            p_low_stock_count := p_low_stock_count + 1;
        END IF;

        DBMS_OUTPUT.PUT_LINE(RPAD(v_line.product_name, 18) || LPAD(v_line.qty, 6)
                             || LPAD(v_line.unit_price, 10) || LPAD(v_line.line_value, 12)
                             || '  ' || v_line.status);

        
        v_already_listed := FALSE;
        FOR i IN 1 .. v_categories.COUNT LOOP
            IF v_categories(i) = v_product.category THEN
                v_already_listed := TRUE;
            END IF;
        END LOOP;
        IF NOT v_already_listed THEN
            v_categories.EXTEND;
            v_categories(v_categories.COUNT) := v_product.category;
        END IF;
    END LOOP;
    v_product_count := c_products%ROWCOUNT;
    CLOSE c_products;

    IF v_product_count = 0 THEN
        RAISE e_no_products;
    END IF;

    DBMS_OUTPUT.PUT_LINE(RPAD('-', 56, '-'));
    DBMS_OUTPUT.PUT_LINE('Products: ' || v_product_count || ' | Total stock value: '
                         || p_total_value || ' RWF | Need reorder: ' || p_low_stock_count);

    DBMS_OUTPUT.PUT('Categories (VARRAY):');
    FOR i IN 1 .. v_categories.COUNT LOOP
        DBMS_OUTPUT.PUT(' ' || v_categories(i));
    END LOOP;
    DBMS_OUTPUT.NEW_LINE;

   
    DBMS_OUTPUT.PUT_LINE('Stock movements:');
    FOR r IN c_movements(p_supplier_id) LOOP
        v_movement_count := v_movement_count + 1;
        DBMS_OUTPUT.PUT_LINE('  ' || TO_CHAR(r.movement_date, 'DD-MON-YYYY') || '  '
                             || RPAD(r.product_name, 18) || RPAD(r.movement_type, 4) || r.quantity);
    END LOOP;
    IF v_movement_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  (none)');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20009, 'Supplier ' || p_supplier_id || ' does not exist.');
    WHEN e_no_products THEN
        RAISE_APPLICATION_ERROR(-20010, 'Supplier ' || p_supplier_id || ' (' || v_supplier_name
                                        || ') has no products to report.');
    WHEN OTHERS THEN
        IF c_products%ISOPEN THEN
            CLOSE c_products;
        END IF;
        RAISE;   -- never hide unexpected errors
END p_supplier_stock_report;
/