# PL/SQL Assignment IV – Records, Collections, Cursors and Bulk Processing

**Course:** Database Development with PL/SQL
**Assignment:** Assignment IV – Records and Collections in Oracle PL/SQL

| Member | Student ID |
|---|---|
| Brian GANZA GISAGARA | 27267 |
| Bruce RUTAGENGWA | 28468 |

Repository: https://github.com/briangisa12/plsql-assignment4-27267-28468

---

## 1. The application: small inventory system

The project is a stock management system for a small shop that buys products from suppliers and sells them.

| Table | Purpose |
|---|---|
| `SUPPLIERS` | Companies that supply products (unique name and e-mail) |
| `PRODUCTS` | Products with category, price, quantity in stock and reorder level |
| `STOCK_MOVEMENTS` | History of every stock IN (delivery) and OUT (sale) |
| `PRICE_CHANGE_LOG` | Audit trail of every price change made by the bulk price procedure |

Integrity is enforced by named constraints: primary keys, foreign keys, `UNIQUE`, and `CHECK` (price > 0, quantity ≥ 0, movement type IN/OUT, movement quantity > 0).

The sample data is chosen on purpose to trigger the interesting cases:
- **"USB Cable" is sold by two suppliers.** A search by name alone raises `TOO_MANY_ROWS`.
- **Blue Pen (Box) and Wireless Mouse are below their reorder level.** They show up in the low-stock reports.
- **Unused Supplier Ltd has no products.** It's used for the "no products" error.
- **Blue Pen costs 4000.** A −5000 bulk price change makes its new price negative, which produces a bulk DML error.

## 2. Business requirements implemented

1. Record a stock IN or OUT movement, never allowing stock to go below zero.
2. Delete a supplier only when it has no products.
3. Show the full details and stock status of one product.
4. Print a stock report for one supplier (products, totals, categories, movements).
5. Increase or decrease the price of every product in a category in one operation, logging each change and reporting the rows that fail.
6. Calculate stock value, find a product by name, and list low-stock products. These are functions usable from both PL/SQL and SQL.

## 3. Project structure

```
README.md
.gitignore
run_all.sql                         rebuilds everything in the right order
00_schema/
    01_create_tables.sql            drops and creates the 4 tables
    02_insert_sample_data.sql       sample suppliers, products, movements
01_procedures/
    p_record_stock_movement.sql
    p_delete_supplier.sql
    p_get_product_details.sql
    p_supplier_stock_report.sql
    p_bulk_price_adjust.sql
02_functions/
    f_stock_value.sql
    f_find_product_id.sql
    f_low_stock_products.sql        also creates the SQL type T_NAME_LIST
03_tests/
    test_success_cases.sql          S1 – S9
    test_error_cases.sql            E1 – E19
    performance_demo.sql            row-by-row vs bulk timing
screenshots/
docs/
    IMPLEMENTATION_NOTES.md
```

## 4. Where each required concept is demonstrated

| Concept | Where |
|---|---|
| `%ROWTYPE` records (table) | `p_get_product_details` (`products%ROWTYPE`, `suppliers%ROWTYPE`) |
| `%ROWTYPE` record (cursor) | `p_supplier_stock_report` (`c_products%ROWTYPE`) |
| User-defined record (`TYPE … IS RECORD`) | `p_supplier_stock_report` (`t_report_line`) |
| VARRAY | `p_supplier_stock_report` (`t_category_list`) |
| Nested table | `p_bulk_price_adjust` (`t_id_list`, `t_price_list`); SQL type `t_name_list` returned by `f_low_stock_products` |
| Associative array (`INDEX BY`) | `p_bulk_price_adjust` (`t_failed_map`) |
| Implicit cursor `SQL%ROWCOUNT` | `p_record_stock_movement`, `p_delete_supplier` |
| Implicit cursor `SQL%FOUND` | `p_record_stock_movement` |
| Implicit cursor `SQL%NOTFOUND` | `p_delete_supplier` |
| Explicit cursor `OPEN / FETCH / CLOSE` with a parameter | `p_supplier_stock_report` (`c_products`) |
| Cursor `FOR` loop | `p_supplier_stock_report` (`c_movements`) |
| `BULK COLLECT … LIMIT` | `p_bulk_price_adjust` |
| `BULK COLLECT` into a SQL collection | `f_low_stock_products` |
| `FORALL … SAVE EXCEPTIONS` + `SQL%BULK_EXCEPTIONS` | `p_bulk_price_adjust` |
| Procedures with `IN` and `OUT` parameters | all 5 procedures |
| Function called from PL/SQL | tests S7, E14 – E17 |
| Function called from SQL | tests S8, S9, E18 |
| `NO_DATA_FOUND` | `p_record_stock_movement`, `p_get_product_details`, `p_supplier_stock_report`, `f_stock_value`, `f_find_product_id` |
| `TOO_MANY_ROWS` | `f_find_product_id` |
| User-defined exceptions | all 5 procedures and `f_low_stock_products` |
| `PRAGMA EXCEPTION_INIT` | `p_delete_supplier` (ORA-02292), `p_bulk_price_adjust` (ORA-24381) |
| `RAISE_APPLICATION_ERROR` | every program (codes −20001 to −20016) |
| No silent errors | every procedure's `WHEN OTHERS` re-raises with `RAISE` (after `ROLLBACK` in the procedures that change data); the functions let unexpected errors propagate |

## 5. Requirements to run

- Oracle Database 19c or later. We used **Oracle AI Database 26ai Free**, with PDB `FREEPDB1`.
- Oracle SQL Developer (we used 26.2) or SQL*Plus.
- A schema user with `CREATE TABLE`, `CREATE PROCEDURE` and `CREATE TYPE` privileges. We used `INVENTORY_APP`.

## 6. How to run

1. Connect to the database as the schema user, in SQL Developer (service name `freepdb1`) or SQL*Plus.
2. Open **`run_all.sql`** and press **F5** (Run Script). It runs, in order: create tables → sample data → 5 procedures → 3 functions. At the end it lists the 13 objects, which should all be `VALID`, and the row counts (4 suppliers, 8 products, 2 movements, 0 price logs).
3. Open **`03_tests/test_success_cases.sql`** and press **F5**.
4. Open **`03_tests/test_error_cases.sql`** and press **F5**.
5. Optional: run **`03_tests/performance_demo.sql`**.

The tests change the data (stock moves, prices rise), so **run `run_all.sql` again before every new test run** to get the same results as the screenshots.

SQL*Plus equivalent, from the repository folder:
```
sqlplus inventory_app/<password>@localhost:1521/freepdb1 @run_all.sql
```

## 7. Test cases

### Success cases (`test_success_cases.sql`)
| # | Test | Expected result (clean data) |
|---|---|---|
| S1 | Stock IN 20 Wireless Mouse | new quantity 28 |
| S2 | Stock OUT 10 A4 Paper | new quantity 190 |
| S3 | Delete a supplier with no products | 1 row deleted |
| S4 | Product details for Blue Pen | value 20000, REORDER NEEDED |
| S5 | Stock report for Rwanda Office Mart | 3 products, total 1 420 000 RWF |
| S6 | ELECTRONICS price +500 (bulk) | 5 updated, 0 failed, 5 log rows |
| S7 | Functions from PL/SQL | value 20000, Keyboard = 4, USB Cable (supplier 3) = 2 |
| S8 | `f_stock_value` inside a `SELECT` | stock value for all 8 products |
| S9 | `TABLE(f_low_stock_products('STATIONERY'))` | Blue Pen (Box) |

### Error cases (`test_error_cases.sql`)
| # | Test | Expected error |
|---|---|---|
| E1 | Quantity 0 | ORA-20001 |
| E2 | Movement type 'XYZ' | ORA-20002 |
| E3 | Product 999 (NO_DATA_FOUND) | ORA-20003 |
| E4 | Sell 50 when only 5 in stock | ORA-20004 |
| E5 | Delete supplier 999 (SQL%NOTFOUND) | ORA-20005 |
| E6 | Delete supplier with products (ORA-02292) | ORA-20006 |
| E7 | Details of product 999 | ORA-20008 |
| E8 | Product ID −1 | ORA-20007 |
| E9 | Report for supplier 999 | ORA-20009 |
| E10 | Report for supplier with no products | ORA-20010 |
| E11 | STATIONERY −5000 (bulk DML error) | 2 updated, 1 failed (ORA-02290 reported for Blue Pen) |
| E12 | Price change amount 0 | ORA-20011 |
| E13 | Category FURNITURE | ORA-20012 |
| E14 | `f_stock_value(999)` | ORA-20013 |
| E15 | `f_find_product_id('USB Cable')` (TOO_MANY_ROWS) | ORA-20015 |
| E16 | `f_find_product_id('Laptop')` | ORA-20014 |
| E17 | `f_low_stock_products('FURNITURE')` | ORA-20016 |
| E18 | `SELECT f_stock_value(999) FROM dual` | ORA-20013 shown in SQL, not a silent NULL |
| E19 | Failed stock OUT, then stock and movements compared before and after | ORA-20004 caught, nothing changed, PASS (proves the ROLLBACK) |

## 8. Screenshots

- `screenshots/test_success_cases_output_1..3.png` and `screenshots/test_error_cases_output_1..4.png`: the **final, clean run** of both test files, taken right after `run_all.sql` (`test_error_cases_output_4.png` shows E19).
- `screenshots/run_all_output.png`: the rebuild, with all objects VALID.
- `screenshots/01_create_tables_output*.png` and `02_sample_data_output.png`: schema creation.
- `screenshots/p_*_success.png`, `p_*_errors.png` and `functions_*.png`: taken while each program was developed. Their numbers can differ from the final run because the data had changed between runs.
- `screenshots/performance_demo_output.png`: the timing comparison.

## 9. Use of an AI assistant

As the assignment requires, we declare that we used an AI assistant, **Claude**, during this assignment.

**How we used it:**
- **As a step-by-step tutor.** It split the assignment into steps (schema, each procedure, functions, tests,) and explained each concept before we used it: records, collections, cursors, bulk processing and exceptions.
- **To draft code.** It proposed the table design and drafts of the procedures, functions and test scripts. We created every file ourselves in SQL Developer, ran it on our own database, and checked the results.
- **For debugging.** It helped us understand and fix the errors we hit: an empty service name (ORA-12261), duplicate data (ORA-00001), a SQL*Plus line-continuation problem in a `PROMPT` line, and Git and GitHub push issues When Github was down.

**What we did ourselves:** we installed and configured the database and tools, created and ran all scripts, checked every output, took the screenshots, made the Git commits, and reviewed as well as understanding the code so we can explain every line in the presentation.
