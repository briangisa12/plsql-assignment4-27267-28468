-- =============================================================
-- Procedure : p_delete_supplier
-- Purpose   : Delete a supplier that has no products.
-- Shows     : implicit cursor with DELETE, SQL%NOTFOUND,
--             SQL%ROWCOUNT, OUT parameter, user-defined
--             exception, PRAGMA EXCEPTION_INIT (ORA-02292),
--             RAISE_APPLICATION_ERROR.
-- Errors    : -20005 supplier not found
--             -20006 supplier still has products
-- =============================================================
CREATE OR REPLACE PROCEDURE p_delete_supplier (
    p_supplier_id  IN  suppliers.supplier_id%TYPE,
    p_rows_deleted OUT NUMBER
) AS
    -- User-defined exception
    e_supplier_not_found  EXCEPTION;

    -- Give Oracle's foreign-key error ORA-02292 a readable name
    e_child_records_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_child_records_exist, -2292);

    v_product_count NUMBER;
BEGIN
    -- Implicit cursor: DELETE
    DELETE FROM suppliers
    WHERE  supplier_id = p_supplier_id;

    -- SQL%NOTFOUND is TRUE when the DELETE touched no rows
    IF SQL%NOTFOUND THEN
        RAISE e_supplier_not_found;
    END IF;

    p_rows_deleted := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('DELETE removed ' || p_rows_deleted || ' row(s) from SUPPLIERS.');

    COMMIT;

EXCEPTION
    WHEN e_supplier_not_found THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20005, 'Supplier ' || p_supplier_id
                                        || ' does not exist. Nothing was deleted.');
    WHEN e_child_records_exist THEN
        ROLLBACK;
        SELECT COUNT(*) INTO v_product_count
        FROM   products
        WHERE  supplier_id = p_supplier_id;
        RAISE_APPLICATION_ERROR(-20006, 'Cannot delete supplier ' || p_supplier_id
                                        || ': it still supplies ' || v_product_count
                                        || ' product(s). Remove or reassign them first.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;   -- never hide unexpected errors
END p_delete_supplier;
/