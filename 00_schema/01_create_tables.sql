SET SERVEROUTPUT ON;
INSERT INTO suppliers (supplier_name, phone, email) VALUES ('Kigali Tech Supplies', '0788000001', 'sales@kts.rw');
INSERT INTO suppliers (supplier_name, phone, email) VALUES ('Rwanda Office Mart',   '0788000002', 'info@rom.rw');
INSERT INTO suppliers (supplier_name, phone, email) VALUES ('EastAfrica Electronics','0788000003', 'hello@eae.rw');
INSERT INTO suppliers (supplier_name, phone, email) VALUES ('Unused Supplier Ltd',  '0788000004', 'x@unused.rw');

INSERT INTO products (product_name, category, supplier_id, unit_price, qty_in_stock, reorder_level)
SELECT 'USB Cable', 'ELECTRONICS', supplier_id, 3500, 120, 20 FROM suppliers WHERE supplier_name='Kigali Tech Supplies';
INSERT INTO products (product_name, category, supplier_id, unit_price, qty_in_stock, reorder_level)
SELECT 'USB Cable', 'ELECTRONICS', supplier_id, 3000, 60, 20 FROM suppliers WHERE supplier_name='EastAfrica Electronics'; 
INSERT INTO products (product_name, category, supplier_id, unit_price, qty_in_stock, reorder_level)
SELECT 'Wireless Mouse', 'ELECTRONICS', supplier_id, 12000, 8, 10 FROM suppliers WHERE supplier_name='Kigali Tech Supplies';  
INSERT INTO products (product_name, category, supplier_id, unit_price, qty_in_stock, reorder_level)
SELECT 'Keyboard', 'ELECTRONICS', supplier_id, 15000, 25, 10 FROM suppliers WHERE supplier_name='EastAfrica Electronics';
INSERT INTO products (product_name, category, supplier_id, unit_price, qty_in_stock, reorder_level)
SELECT 'A4 Paper Ream', 'STATIONERY', supplier_id, 6500, 200, 50 FROM suppliers WHERE supplier_name='Rwanda Office Mart';
INSERT INTO products (product_name, category, supplier_id, unit_price, qty_in_stock, reorder_level)
SELECT 'Blue Pen (Box)', 'STATIONERY', supplier_id, 4000, 5, 15 FROM suppliers WHERE supplier_name='Rwanda Office Mart';   
INSERT INTO products (product_name, category, supplier_id, unit_price, qty_in_stock, reorder_level)
SELECT 'Stapler', 'STATIONERY', supplier_id, 5500, 30, 10 FROM suppliers WHERE supplier_name='Rwanda Office Mart';
INSERT INTO products (product_name, category, supplier_id, unit_price, qty_in_stock, reorder_level)
SELECT 'HDMI Cable', 'ELECTRONICS', supplier_id, 7000, 40, 10 FROM suppliers WHERE supplier_name='EastAfrica Electronics';

INSERT INTO stock_movements (product_id, movement_type, quantity, note)
SELECT product_id, 'IN', 50, 'Initial delivery' FROM products WHERE product_name='Keyboard';
INSERT INTO stock_movements (product_id, movement_type, quantity, note)
SELECT product_id, 'OUT', 10, 'Sold to AUCA ICT lab' FROM products WHERE product_name='A4 Paper Ream';

COMMIT;