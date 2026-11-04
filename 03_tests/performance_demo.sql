
SET SERVEROUTPUT ON

PROMPT ===== Performance demo: row-by-row vs BULK COLLECT / FORALL =====

-- A scratch table only for this demo (dropped at the end)
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE perf_demo PURGE';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN RAISE; END IF;   -- -942 = table does not exist
END;
/
CREATE TABLE perf_demo (id NUMBER PRIMARY KEY, amount NUMBER);

DECLARE
    c_rows CONSTANT PLS_INTEGER := 50000;

    TYPE t_num_list IS TABLE OF NUMBER;
    v_ids     t_num_list := t_num_list();
    v_amounts t_num_list := t_num_list();

    v_start PLS_INTEGER;
    v_slow  PLS_INTEGER;
    v_fast  PLS_INTEGER;
    v_sum   NUMBER := 0;
    v_id     NUMBER;
    v_amount NUMBER;
    CURSOR c_demo IS SELECT id, amount FROM perf_demo;
BEGIN
    v_ids.EXTEND(c_rows);
    v_amounts.EXTEND(c_rows);
    FOR i IN 1 .. c_rows LOOP
        v_ids(i)     := i;
        v_amounts(i) := MOD(i, 100);
    END LOOP;

    -- 1) INSERT: row by row (one context switch per row)
    v_start := DBMS_UTILITY.GET_TIME;
    FOR i IN 1 .. c_rows LOOP
        INSERT INTO perf_demo (id, amount) VALUES (v_ids(i), v_amounts(i));
    END LOOP;
    v_slow := DBMS_UTILITY.GET_TIME - v_start;
    ROLLBACK;

    -- 2) INSERT: FORALL (all rows sent to SQL in one call)
    v_start := DBMS_UTILITY.GET_TIME;
    FORALL i IN 1 .. c_rows
        INSERT INTO perf_demo (id, amount) VALUES (v_ids(i), v_amounts(i));
    v_fast := DBMS_UTILITY.GET_TIME - v_start;
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('INSERT ' || c_rows || ' rows');
    DBMS_OUTPUT.PUT_LINE('  row by row loop : ' || TO_CHAR(v_slow / 100, '990.00') || ' s');
    DBMS_OUTPUT.PUT_LINE('  FORALL          : ' || TO_CHAR(v_fast / 100, '990.00') || ' s');

    -- 3) FETCH: explicit cursor, one row per FETCH
    v_start := DBMS_UTILITY.GET_TIME;
    OPEN c_demo;
    LOOP
        FETCH c_demo INTO v_id, v_amount;
        EXIT WHEN c_demo%NOTFOUND;
        v_sum := v_sum + v_amount;
    END LOOP;
    CLOSE c_demo;
    v_slow := DBMS_UTILITY.GET_TIME - v_start;

    -- 4) FETCH: BULK COLLECT into collections
    v_ids.DELETE;
    v_amounts.DELETE;
    v_start := DBMS_UTILITY.GET_TIME;
    SELECT id, amount BULK COLLECT INTO v_ids, v_amounts FROM perf_demo;
    v_fast := DBMS_UTILITY.GET_TIME - v_start;

    DBMS_OUTPUT.PUT_LINE('FETCH ' || v_ids.COUNT || ' rows');
    DBMS_OUTPUT.PUT_LINE('  row by row FETCH: ' || TO_CHAR(v_slow / 100, '990.00') || ' s');
    DBMS_OUTPUT.PUT_LINE('  BULK COLLECT    : ' || TO_CHAR(v_fast / 100, '990.00') || ' s');
END;
/

DROP TABLE perf_demo PURGE;
