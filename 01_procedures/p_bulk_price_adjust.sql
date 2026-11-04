
CREATE OR REPLACE PROCEDURE p_bulk_price_adjust (
    p_category      IN  products.category%TYPE,
    p_amount        IN  NUMBER,
    p_updated_count OUT PLS_INTEGER,
    p_failed_count  OUT PLS_INTEGER
) AS
    -- Collection types
    TYPE t_id_list    IS TABLE OF products.product_id%TYPE;            -- nested table
    TYPE t_price_list IS TABLE OF products.unit_price%TYPE;            -- nested table
    TYPE t_failed_map IS TABLE OF BOOLEAN INDEX BY PLS_INTEGER;        -- associative array

    v_ids        t_id_list;
    v_old_prices t_price_list;
    v_new_prices t_price_list := t_price_list();
    v_failed     t_failed_map;
    v_log_ids    t_id_list    := t_id_list();
    v_log_old    t_price_list := t_price_list();
    v_log_new    t_price_list := t_price_list();

    CURSOR c_products IS
        SELECT product_id, unit_price
        FROM   products
        WHERE  UPPER(category) = UPPER(TRIM(p_category))
        ORDER  BY product_id;

    c_batch_size CONSTANT PLS_INTEGER := 100;
    v_total_rows PLS_INTEGER := 0;
    v_err_index  PLS_INTEGER;

    -- ORA-24381 is raised by FORALL ... SAVE EXCEPTIONS when any row fails
    e_bulk_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_bulk_errors, -24381);

    e_invalid_amount EXCEPTION;
    e_no_products    EXCEPTION;
BEGIN
    IF p_amount IS NULL OR p_amount = 0 THEN
        RAISE e_invalid_amount;
    END IF;

    p_updated_count := 0;
    p_failed_count  := 0;

    OPEN c_products;
    LOOP
    
        FETCH c_products BULK COLLECT INTO v_ids, v_old_prices LIMIT c_batch_size;
        EXIT WHEN v_ids.COUNT = 0;
        v_total_rows := v_total_rows + v_ids.COUNT;

    
        v_new_prices.DELETE;
        v_new_prices.EXTEND(v_ids.COUNT);
        FOR i IN 1 .. v_ids.COUNT LOOP
            v_new_prices(i) := v_old_prices(i) + p_amount;
        END LOOP;


        v_failed.DELETE;
        BEGIN
            FORALL i IN 1 .. v_ids.COUNT SAVE EXCEPTIONS
                UPDATE products
                SET    unit_price = v_new_prices(i)
                WHERE  product_id = v_ids(i);
        EXCEPTION
            WHEN e_bulk_errors THEN
                FOR j IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                    v_err_index := SQL%BULK_EXCEPTIONS(j).ERROR_INDEX;
                    v_failed(v_err_index) := TRUE;
                    DBMS_OUTPUT.PUT_LINE('  FAILED product ' || v_ids(v_err_index)
                        || ' (old ' || v_old_prices(v_err_index)
                        || ', new ' || v_new_prices(v_err_index) || '): '
                        || SQLERRM(-SQL%BULK_EXCEPTIONS(j).ERROR_CODE));
                END LOOP;
        END;

        
        v_log_ids.DELETE;
        v_log_old.DELETE;
        v_log_new.DELETE;
        FOR i IN 1 .. v_ids.COUNT LOOP
            IF NOT v_failed.EXISTS(i) THEN
                v_log_ids.EXTEND; v_log_ids(v_log_ids.LAST) := v_ids(i);
                v_log_old.EXTEND; v_log_old(v_log_old.LAST) := v_old_prices(i);
                v_log_new.EXTEND; v_log_new(v_log_new.LAST) := v_new_prices(i);
            END IF;
        END LOOP;

        
        FORALL i IN 1 .. v_log_ids.COUNT
            INSERT INTO price_change_log (product_id, old_price, new_price)
            VALUES (v_log_ids(i), v_log_old(i), v_log_new(i));

        p_updated_count := p_updated_count + v_log_ids.COUNT;
        p_failed_count  := p_failed_count  + v_failed.COUNT;
    END LOOP;
    CLOSE c_products;

    IF v_total_rows = 0 THEN
        RAISE e_no_products;
    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Category ' || UPPER(p_category) || ': ' || v_total_rows
                         || ' product(s) processed, ' || p_updated_count || ' updated, '
                         || p_failed_count || ' failed.');
EXCEPTION
    WHEN e_invalid_amount THEN
        RAISE_APPLICATION_ERROR(-20011, 'Price change amount must be a non-zero number. Given: '
                                        || NVL(TO_CHAR(p_amount), 'NULL'));
    WHEN e_no_products THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20012, 'No products found in category '
                                        || NVL(p_category, 'NULL') || '.');
    WHEN OTHERS THEN
        IF c_products%ISOPEN THEN
            CLOSE c_products;
        END IF;
        ROLLBACK;
        RAISE;   -- never hide unexpected errors
END p_bulk_price_adjust;
/