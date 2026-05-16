
-- Notes.

-- alegerea cu unique de ce nu am limit 1


--Task 3

-- Task 3.1.
-- Create a physical database with a separate database and schema and give it an appropriate domain-related name

-- CREATE DATABASE household_appliances_store;

DROP SCHEMA IF EXISTS store_schema CASCADE;

CREATE SCHEMA IF NOT EXISTS store_schema;


-- Task 3.2

-- Create relationships between tables using primary and foreign keys. 
-- Create tables in the correct DDL order: parent tables before child tables to avoid foreign key errors
-- Use appropriate data types for each column and apply DEFAULT, STORED AS and GENERATED ALWAYS AS columns as required.

-- NOTES:

-- For tables order_line and procurement_line a column called unit_price was added.
-- - product.product_price = current selling price.
-- - order_line.unit_price = historical selling price at the moment of the order.
-- - procurement_line.unit_price = historical purchase cost at the moment of procurement.
-- Because these columns describe different business facts , 
-- it does not violate 3NF (unit_price in the transaction line is not the same fact as the current price in product).

-- Also, a new calculated column line_total was added.
-- This column is derived from quantity * unit_price and it is stored as a generated column because the assignment requires GENERATED ALWAYS AS ... STORED. 

-- Tabel 1. Customer

CREATE TABLE IF NOT EXISTS store_schema.customer (
    customer_id INT GENERATED ALWAYS AS IDENTITY,
    customer_first_name VARCHAR(100) NOT NULL,
    customer_last_name VARCHAR(100) NOT NULL,
    customer_email VARCHAR(100) NOT NULL,
    customer_telephone VARCHAR(20) NOT NULL,
    customer_address VARCHAR(200) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_customer PRIMARY KEY (customer_id),
    CONSTRAINT uq_customer_email UNIQUE (customer_email),
    CONSTRAINT uq_customer_telephone UNIQUE (customer_telephone),
    CONSTRAINT chk_customer_created_after_2026
        CHECK (created_at > TIMESTAMP '2026-01-02 00:00:00')
);

-- Table 2. Supplier

CREATE TABLE IF NOT EXISTS store_schema.supplier (
    supplier_id INT GENERATED ALWAYS AS IDENTITY,
    supplier_name VARCHAR(200) NOT NULL,
    supplier_fiscal_code VARCHAR(20) NOT NULL,
    supplier_email VARCHAR(100) NOT NULL,
    supplier_telephone VARCHAR(20) NOT NULL,
    supplier_address VARCHAR(200) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_supplier PRIMARY KEY (supplier_id),
    CONSTRAINT uq_supplier_fiscal_code UNIQUE (supplier_fiscal_code),
    CONSTRAINT uq_supplier_email UNIQUE (supplier_email),
    CONSTRAINT uq_supplier_telephone UNIQUE (supplier_telephone),
    CONSTRAINT chk_supplier_created_after_2026
        CHECK (created_at > TIMESTAMP '2026-01-02 00:00:00')
);


-- Table 3. Employee

CREATE TABLE IF NOT EXISTS store_schema.employee (
    employee_id INT GENERATED ALWAYS AS IDENTITY,
    employee_first_name VARCHAR(100) NOT NULL,
    employee_last_name VARCHAR(100) NOT NULL,
    employee_email VARCHAR(100) NOT NULL,
    employee_telephone VARCHAR(20) NOT NULL,
    employee_role VARCHAR(100) NOT NULL,
    employee_hire_date DATE NOT NULL DEFAULT CURRENT_DATE,
    employee_salary NUMERIC(12,2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_employee PRIMARY KEY (employee_id),
    CONSTRAINT uq_employee_email UNIQUE (employee_email),
    CONSTRAINT uq_employee_telephone UNIQUE (employee_telephone),
    CONSTRAINT chk_employee_salary_positive
        CHECK (employee_salary > 0),
    CONSTRAINT chk_employee_created_after_2026
        CHECK (created_at > TIMESTAMP '2026-01-02 00:00:00'),
    CONSTRAINT chk_employee_hire_date_after_2026
        CHECK (employee_hire_date >= DATE '2026-01-02')
);

-- Table 4. Category

CREATE TABLE IF NOT EXISTS store_schema.category (
    category_id INT GENERATED ALWAYS AS IDENTITY,
    category_name VARCHAR(100) NOT NULL,
    category_description VARCHAR(200) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_category PRIMARY KEY (category_id),
    CONSTRAINT uq_category_name UNIQUE (category_name),
    CONSTRAINT chk_category_created_after_2026
        CHECK (created_at > TIMESTAMP '2026-01-02 00:00:00')
);

-- Table 5. Brand

CREATE TABLE IF NOT EXISTS store_schema.brand (
    brand_id INT GENERATED ALWAYS AS IDENTITY,
    brand_name VARCHAR(100) NOT NULL,
    brand_description VARCHAR(200) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_brand PRIMARY KEY (brand_id),
    CONSTRAINT uq_brand_name UNIQUE (brand_name),
    CONSTRAINT chk_brand_created_after_2026
        CHECK (created_at > TIMESTAMP '2026-01-02 00:00:00')
);

-- Tabel 6. Product

CREATE TABLE IF NOT EXISTS store_schema.product (
    product_id INT GENERATED ALWAYS AS IDENTITY,
    category_id INT NOT NULL,
    brand_id INT NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    product_model VARCHAR(100) NOT NULL,
    product_price NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_product PRIMARY KEY (product_id),

    CONSTRAINT fk_product_category FOREIGN KEY (category_id)
        REFERENCES store_schema.category(category_id),

    CONSTRAINT fk_product_brand FOREIGN KEY (brand_id)
        REFERENCES store_schema.brand(brand_id),

    CONSTRAINT uq_product_brand_name_model
        UNIQUE (brand_id, product_name, product_model),

    CONSTRAINT chk_product_price_positive
        CHECK (product_price > 0),

    CONSTRAINT chk_product_created_after_2026
        CHECK (created_at > TIMESTAMP '2026-01-02 00:00:00')
);

-- Table 7. Customer Order
-- Some constraints are added later with ALTER TABLE to demonstrate the requested use cases.

CREATE TABLE IF NOT EXISTS store_schema.customer_order (
    order_id INT GENERATED ALWAYS AS IDENTITY,
    customer_id INT NOT NULL,
    employee_id INT NOT NULL,
    order_number VARCHAR(25) NOT NULL,
    order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    order_status VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_customer_order PRIMARY KEY (order_id),

    CONSTRAINT fk_order_customer FOREIGN KEY (customer_id)
        REFERENCES store_schema.customer(customer_id),

    CONSTRAINT fk_order_employee FOREIGN KEY (employee_id)
        REFERENCES store_schema.employee(employee_id),

    CONSTRAINT chk_order_created_after_2026
        CHECK (created_at > TIMESTAMP '2026-01-02 00:00:00')
);

-- Table 8. Order Line
-- The quantity CHECK constraint is added later with ALTER TABLE.

CREATE TABLE IF NOT EXISTS store_schema.order_line (
    order_item_id INT GENERATED ALWAYS AS IDENTITY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL,
    line_total NUMERIC(12,2)
        GENERATED ALWAYS AS (quantity * unit_price) STORED,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_order_line PRIMARY KEY (order_item_id),

    CONSTRAINT fk_order_line_order FOREIGN KEY (order_id)
        REFERENCES store_schema.customer_order(order_id),

    CONSTRAINT fk_order_line_product FOREIGN KEY (product_id)
        REFERENCES store_schema.product(product_id),

    CONSTRAINT uq_order_product UNIQUE (order_id, product_id),

    CONSTRAINT chk_order_line_unit_price_positive
        CHECK (unit_price > 0),

    CONSTRAINT chk_order_line_created_after_2026
        CHECK (created_at > TIMESTAMP '2026-01-02 00:00:00')
);

-- Table 9. Procurement

CREATE TABLE IF NOT EXISTS store_schema.procurement (
    procurement_id INT GENERATED ALWAYS AS IDENTITY,
    supplier_id INT NOT NULL,
    employee_id INT NOT NULL,
    procurement_number VARCHAR(25) NOT NULL,
    procurement_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    procurement_status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_procurement PRIMARY KEY (procurement_id),

    CONSTRAINT fk_procurement_supplier FOREIGN KEY (supplier_id)
        REFERENCES store_schema.supplier(supplier_id),

    CONSTRAINT fk_procurement_employee FOREIGN KEY (employee_id)
        REFERENCES store_schema.employee(employee_id),

    CONSTRAINT uq_procurement_number UNIQUE (procurement_number),

    CONSTRAINT chk_procurement_status_valid
        CHECK (procurement_status IN ('PLACED', 'PENDING', 'SHIPPED', 'DELIVERED')),

    CONSTRAINT chk_procurement_created_after_2026
        CHECK (created_at > TIMESTAMP '2026-01-02 00:00:00'),

    CONSTRAINT chk_procurement_date_after_2026
        CHECK (procurement_date > TIMESTAMP '2026-01-02 00:00:00')
);

-- Table 10. Procurement Line

CREATE TABLE IF NOT EXISTS store_schema.procurement_line (
    procurement_item_id INT GENERATED ALWAYS AS IDENTITY,
    procurement_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL,
    line_total NUMERIC(12,2)
        GENERATED ALWAYS AS (quantity * unit_price) STORED,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_procurement_line PRIMARY KEY (procurement_item_id),

    CONSTRAINT fk_procurement_line_procurement FOREIGN KEY (procurement_id)
        REFERENCES store_schema.procurement(procurement_id),

    CONSTRAINT fk_procurement_line_product FOREIGN KEY (product_id)
        REFERENCES store_schema.product(product_id),

    CONSTRAINT uq_procurement_line_procurement_product
        UNIQUE (procurement_id, product_id),

    CONSTRAINT chk_procurement_line_quantity_positive
        CHECK (quantity > 0),

    CONSTRAINT chk_procurement_line_unit_price_positive
        CHECK (unit_price > 0),

    CONSTRAINT chk_procurement_line_created_after_2026
        CHECK (created_at > TIMESTAMP '2026-01-02 00:00:00')
);

-- Table 11. Inventory Movement

CREATE TABLE IF NOT EXISTS store_schema.inventory_movement (
    inventory_movement_id INT GENERATED ALWAYS AS IDENTITY,
    product_id INT NOT NULL,
    employee_id INT NOT NULL,
    movement_type VARCHAR(5) NOT NULL,
    quantity INT NOT NULL,
    movement_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_inventory_movement PRIMARY KEY (inventory_movement_id),

    CONSTRAINT fk_inventory_movement_product FOREIGN KEY (product_id)
        REFERENCES store_schema.product(product_id),

    CONSTRAINT fk_inventory_movement_employee FOREIGN KEY (employee_id)
        REFERENCES store_schema.employee(employee_id),

    CONSTRAINT chk_inventory_movement_type_valid
        CHECK (movement_type IN ('IN', 'OUT')),

    CONSTRAINT chk_inventory_movement_quantity_positive
        CHECK (quantity > 0),

    CONSTRAINT chk_inventory_movement_date_after_2026
        CHECK (movement_date > TIMESTAMP '2026-01-02 00:00:00'),

    CONSTRAINT chk_inventory_movement_created_after_2026
        CHECK (created_at > TIMESTAMP '2026-01-02 00:00:00')
);

-- Task 3.3.

-- Use ALTER TABLE to add at least 5 check constraints across the tables to restrict certain values, as example 
-- -  date to be inserted, which must be greater than January 1, 2026
-- - inserted measured value that cannot be negative
-- - inserted value that can only be a specific value
-- - unique
-- - not null
--Give meaningful names to your CHECK constraints. 

-- NOTES:
-- Most constraints were defined directly at table level to keep the DDL script readable. 
-- However, because the assignment specifically requires constraints to be added using ALTER TABLE, 
-- five different constraints were intentionally kept as ALTER TABLE examples.

-- 1. UNIQUE: each order number must identify one customer order
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'uq_order_number'
    ) THEN
        ALTER TABLE store_schema.customer_order
        ADD CONSTRAINT uq_order_number
        UNIQUE (order_number);
    END IF;
END $$;

-- 2. NOT NULL: each order must have a status
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'store_schema'
          AND table_name = 'customer_order'
          AND column_name = 'order_status'
          AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE store_schema.customer_order
        ALTER COLUMN order_status SET NOT NULL;
    END IF;
END $$;

-- 3. Date check: order date must be after January 1, 2026
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_order_date_after_2026'
    ) THEN
        ALTER TABLE store_schema.customer_order
        ADD CONSTRAINT chk_order_date_after_2026
        CHECK (order_date > TIMESTAMP '2026-01-01 00:00:00');
    END IF;
END $$;

-- 4. Specific value check: order status must be one of the allowed values
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_order_status_valid'
    ) THEN
        ALTER TABLE store_schema.customer_order
        ADD CONSTRAINT chk_order_status_valid
        CHECK (order_status IN ('PLACED', 'PENDING', 'SHIPPED', 'DELIVERED'));
    END IF;
END $$;

-- 5. Measured value check: ordered quantity must be positive
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_order_line_quantity_positive'
    ) THEN
        ALTER TABLE store_schema.order_line
        ADD CONSTRAINT chk_order_line_quantity_positive
        CHECK (quantity > 0);
    END IF;
END $$;


-- Task 4

-- Populate the tables with the sample data generated, ensuring each table has at least 6+ rows (for a total of 36+ rows in all the tables) for the last 3 months.
-- Create DML scripts for insert your data. 
-- Ensure that the DML scripts do not include values for surrogate keys, as these keys should be generated by the database during runtime. 
-- Avoid hardcoding values where possible
-- Also, ensure that any DEFAULT values required are specified appropriately in the DML scripts
-- These DML scripts should be designed to successfully adhere to all previously defined constraints

-- NOTES:

-- Joins were used instead of SELECT ... LIMIT 1 
-- because the referenced tables contain unique business columns, such as category names, brand names, emails, order numbers, and procurement numbers.
-- For example, category_name and brand_name are defined as unique, so each join can match at most one row. 
-- Because the database enforces this uniqueness, there is no risk of returning multiple compatible records, and LIMIT 1 is not needed.

-- Table 1. Customer 

INSERT INTO store_schema.customer (
    customer_first_name,
    customer_last_name,
    customer_email,
    customer_telephone,
    customer_address,
    created_at
)
VALUES
	(UPPER('james'), UPPER('brown'), LOWER('james.brown@email.com'), '0711111111', UPPER('new york'), '2026-02-05'),
	(UPPER('mary'), UPPER('johnson'), LOWER('mary.johnson@email.com'), '0722222222', UPPER('los angeles'), '2026-02-14'),
	(UPPER('robert'), UPPER('williams'), LOWER('robert.williams@email.com'), '0733333333', UPPER('chicago'), '2026-03-01'),
	(UPPER('patricia'), UPPER('green'), LOWER('patricia.green@email.com'), '0744444444', UPPER('houston'), '2026-03-18'),
	(UPPER('john'), UPPER('myers'), LOWER('john.myers@email.com'), '0755555555', UPPER('new york'), '2026-04-03'),
	(UPPER('jennifer'), UPPER('garcia'), LOWER('jennifer.garcia@email.com'), '0766666666', UPPER('new york'), '2026-04-20')
ON CONFLICT (customer_email) DO NOTHING
RETURNING *;

-- Table 2. Customer 

INSERT INTO store_schema.supplier (
    supplier_name,
    supplier_fiscal_code,
    supplier_email,
    supplier_telephone,
    supplier_address,
    created_at
)
VALUES
	(UPPER('alias group'), 'RO100001', LOWER('contact@aliasgroup.com'), '0771000001', UPPER('new york'), '2026-02-05'),
	(UPPER('hq electronics'), 'RO100002', LOWER('office@hqelectronics.com'), '0771000002', UPPER('los angeles'), '2026-02-14'),
	(UPPER('smart components'), 'RO100003', LOWER('sales@smartcomponents.com'), '0771000003', UPPER('chicago'), '2026-03-01'),
	(UPPER('zevillon distribution'), 'RO100004', LOWER('contact@zevillondistribution.com'), '0771000004', UPPER('chicago'), '2026-03-18'),
	(UPPER('ch sale'), 'RO100005', LOWER('office@chsale.com'), '0771000005', UPPER('phoenix'), '2026-04-03'),
	(UPPER('europe imports'), 'RO100006', LOWER('sales@euimports.com'), '0771000006', UPPER('los angeles'), '2026-04-20')
ON CONFLICT (supplier_fiscal_code) DO NOTHING
RETURNING *;

-- Table 3. Employee

INSERT INTO store_schema.employee (
    employee_first_name,
    employee_last_name,
    employee_email,
    employee_telephone,
    employee_role,
    employee_hire_date,
    employee_salary,
    created_at
)
VALUES
	(UPPER('michael'), UPPER('miller'), LOWER('michael.miller@store.com'), '0781000001', UPPER('manager'), '2026-02-05', 5200, '2026-02-05 10:00:00'),
	(UPPER('linda'), UPPER('davis'), LOWER('linda.davis@store.com'), '0781000002', UPPER('cashier'), '2026-02-14', 3100, '2026-02-14 11:00:00'),
	(UPPER('william'), UPPER('wilson'), LOWER('william.wilson@store.com'), '0781000003', UPPER('sales'), '2026-03-01', 3400, '2026-03-01 09:30:00'),
	(UPPER('elizabeth'), UPPER('moore'), LOWER('elizabeth.moore@store.com'), '0781000004', UPPER('warehouse'), '2026-03-18', 3000, '2026-03-18 12:00:00'),
	(UPPER('david'), UPPER('taylor'), LOWER('david.taylor@store.com'), '0781000005', UPPER('sales'), '2026-04-03', 3600, '2026-04-03 14:00:00'),
	(UPPER('barbara'), UPPER('anderson'), LOWER('barbara.anderson@store.com'), '0781000006', UPPER('manager'), '2026-04-20', 5500, '2026-04-20 16:00:00')
ON CONFLICT (employee_email) DO NOTHING
RETURNING *;

-- Table 4. Category

INSERT INTO store_schema.category (
    category_name,
    category_description,
    created_at
)
VALUES
	(UPPER('kitchen appliances'), UPPER('appliances used for cooking and food preparation'), '2026-02-05 10:00:00'),
	(UPPER('cleaning appliances'), UPPER('vacuum cleaners and cleaning devices'), '2026-02-14 11:00:00'),
	(UPPER('laundry appliances'), UPPER('washing machines and dryers'), '2026-03-01 09:30:00'),
	(UPPER('heating and cooling'), UPPER('air conditioners heaters and fans'), '2026-03-18 12:00:00'),
	(UPPER('small appliances'), UPPER('toasters kettles and coffee machines'), '2026-04-03 14:00:00'),
	(UPPER('large appliances'), UPPER('refrigerators ovens and dishwashers'), '2026-04-20 16:00:00')
ON CONFLICT (category_name) DO NOTHING
RETURNING *;

-- Table 5. Brand

INSERT INTO store_schema.brand (
    brand_name,
    brand_description,
    created_at
)
VALUES
	(UPPER('bosch'), UPPER('german home appliances manufacturer'), '2026-02-05 10:00:00'),
	(UPPER('lg'), UPPER('consumer electronics and home appliances brand'), '2026-02-14 11:00:00'),
	(UPPER('samsung'), UPPER('electronics and home appliances brand'), '2026-03-01 09:30:00'),
	(UPPER('whirlpool'), UPPER('american home appliances manufacturer'), '2026-03-18 12:00:00'),
	(UPPER('electrolux'), UPPER('swedish appliances manufacturer'), '2026-04-03 14:00:00'),
	(UPPER('philips'), UPPER('health technology and small appliances brand'), '2026-04-20 16:00:00')
ON CONFLICT (brand_name) DO NOTHING
RETURNING *;

-- Table 6. Product 

INSERT INTO store_schema.product (
    category_id,
    brand_id,
    product_name,
    product_model,
    product_price,
    created_at
)
SELECT
    c.category_id,
    b.brand_id,
    UPPER(v.product_name),
    UPPER(v.product_model),
    v.product_price,
    v.created_at
FROM (
    VALUES
        ('kitchen appliances', 'bosch', 'oven', 'series 6', 3200.00, TIMESTAMP '2026-02-06 10:00:00'),
        ('cleaning appliances', 'lg', 'vacuum cleaner', 'cordzero', 1800.00, TIMESTAMP '2026-02-15 11:00:00'),
        ('laundry appliances', 'samsung', 'washing machine', 'eco bubble', 2500.00, TIMESTAMP '2026-03-02 09:30:00'),
        ('heating and cooling', 'whirlpool', 'air conditioner', 'inverter pro', 2700.00, TIMESTAMP '2026-03-19 12:00:00'),
        ('large appliances', 'philips', 'refrigerator', 'no frost', 4200.00, TIMESTAMP '2026-04-21 16:00:00'),
        ('large appliances', 'whirlpool', 'washing machine', 'eco', 2200.00, TIMESTAMP '2026-03-21 17:00:00')
) AS v(category_name, brand_name, product_name, product_model, product_price, created_at)
JOIN store_schema.category c
    ON c.category_name = UPPER(v.category_name)
JOIN store_schema.brand b
    ON b.brand_name = UPPER(v.brand_name)
ON CONFLICT (brand_id, product_name, product_model) DO NOTHING
RETURNING *;

-- Table 7. Customer Order

INSERT INTO store_schema.customer_order (
    customer_id,
    employee_id,
    order_number,
    order_date,
    order_status,
    created_at
)
SELECT
    c.customer_id,
    e.employee_id,
    v.order_number,
    v.order_date,
    UPPER(v.order_status),
    v.created_at
FROM (
    VALUES
    ('james.brown@email.com', 'michael.miller@store.com', 'ORD001', TIMESTAMP '2026-02-06 10:00:00', 'placed', TIMESTAMP '2026-02-06 10:00:00'),
    ('mary.johnson@email.com', 'linda.davis@store.com', 'ORD002', TIMESTAMP '2026-02-15 11:00:00', 'pending', TIMESTAMP '2026-02-15 11:00:00'),
    ('robert.williams@email.com', 'william.wilson@store.com', 'ORD003', TIMESTAMP '2026-03-02 09:30:00', 'shipped', TIMESTAMP '2026-03-02 09:30:00'),
    ('patricia.green@email.com', 'elizabeth.moore@store.com', 'ORD004', TIMESTAMP '2026-03-19 12:00:00', 'delivered', TIMESTAMP '2026-03-19 12:00:00'),
    ('jennifer.garcia@email.com', 'barbara.anderson@store.com', 'ORD005', TIMESTAMP '2026-04-20 16:00:00', 'pending', TIMESTAMP '2026-04-20 16:00:00'),
    ('james.brown@email.com', 'linda.davis@store.com', 'ORD006', TIMESTAMP '2026-04-22 13:00:00', 'shipped', TIMESTAMP '2026-04-22 13:00:00'),
    ('james.brown@email.com', 'william.wilson@store.com', 'ORD007', TIMESTAMP '2026-04-24 15:30:00', 'placed', TIMESTAMP '2026-04-24 15:30:00')
) AS v(customer_email, employee_email, order_number, order_date, order_status, created_at)
JOIN store_schema.customer c
    ON c.customer_email = LOWER(v.customer_email)
JOIN store_schema.employee e
    ON e.employee_email = LOWER(v.employee_email)
ON CONFLICT (order_number) DO NOTHING
RETURNING *;

-- Table 8. Order Line

INSERT INTO store_schema.order_line (
    order_id,
    product_id,
    quantity,
    unit_price,
    created_at
)
SELECT
    o.order_id,
    p.product_id,
    v.quantity,
    v.unit_price,
    v.created_at
FROM (
    VALUES
        ('ORD001', 'bosch', 'oven', 'series 6', 1, 3200.00, TIMESTAMP '2026-02-06 10:05:00'),
        ('ORD002', 'lg', 'vacuum cleaner', 'cordzero', 2, 1800.00, TIMESTAMP '2026-02-15 11:05:00'),
        ('ORD003', 'samsung', 'washing machine', 'eco bubble', 1, 2500.00, TIMESTAMP '2026-03-02 09:35:00'),
        ('ORD004', 'whirlpool', 'air conditioner', 'inverter pro', 1, 2700.00, TIMESTAMP '2026-03-19 12:05:00'),
        ('ORD005', 'philips', 'refrigerator', 'no frost', 1, 4200.00, TIMESTAMP '2026-04-20 16:05:00'),
        ('ORD006', 'whirlpool', 'washing machine', 'eco', 2, 2200.00, TIMESTAMP '2026-04-22 13:05:00'),
        ('ORD006', 'whirlpool', 'air conditioner', 'inverter pro', 2, 2400.00, TIMESTAMP '2026-04-22 13:05:00'),
        ('ORD007', 'whirlpool', 'washing machine', 'eco', 2, 2200.00, TIMESTAMP '2026-04-28 13:05:00')
) AS v(order_number, brand_name, product_name, product_model, quantity, unit_price, created_at)
JOIN store_schema.customer_order o
    ON o.order_number = UPPER(v.order_number)
JOIN store_schema.brand b
    ON b.brand_name = UPPER(v.brand_name)
JOIN store_schema.product p
    ON p.brand_id = b.brand_id
   AND p.product_name = UPPER(v.product_name)
   AND p.product_model = UPPER(v.product_model)
ON CONFLICT (order_id, product_id) DO NOTHING
RETURNING *;

-- Table 9. Procurement
INSERT INTO store_schema.procurement (
    supplier_id,
    employee_id,
    procurement_number,
    procurement_date,
    procurement_status,
    created_at
)
SELECT
    s.supplier_id,
    e.employee_id,
    UPPER(v.procurement_number),
    v.procurement_date,
    UPPER(v.procurement_status),
    v.created_at
FROM (
    VALUES
    (UPPER('ro100001'), 'michael.miller@store.com', 'prc001', TIMESTAMP '2026-02-07 10:00:00', 'placed', TIMESTAMP '2026-02-07 10:00:00'),
    (UPPER('ro100002'), 'linda.davis@store.com', 'prc002', TIMESTAMP '2026-02-16 11:00:00', 'pending', TIMESTAMP '2026-02-16 11:00:00'),
    (UPPER('ro100003'), 'william.wilson@store.com', 'prc003', TIMESTAMP '2026-03-03 09:30:00', 'shipped', TIMESTAMP '2026-03-03 09:30:00'),
    (UPPER('ro100004'), 'elizabeth.moore@store.com', 'prc004', TIMESTAMP '2026-03-20 12:00:00', 'delivered', TIMESTAMP '2026-03-20 12:00:00'),
    (UPPER('ro100005'), 'david.taylor@store.com', 'prc005', TIMESTAMP '2026-04-05 14:00:00', 'placed', TIMESTAMP '2026-04-05 14:00:00'),
    (UPPER('ro100006'), 'william.wilson@store.com', 'prc006', TIMESTAMP '2026-04-22 16:00:00', 'pending', TIMESTAMP '2026-04-22 16:00:00')
) AS v(supplier_fiscal_code, employee_email, procurement_number, procurement_date, procurement_status, created_at)
JOIN store_schema.supplier s
    ON s.supplier_fiscal_code = UPPER(v.supplier_fiscal_code)
JOIN store_schema.employee e
    ON e.employee_email = LOWER(v.employee_email)
ON CONFLICT (procurement_number) DO NOTHING
RETURNING *;

-- Table 10. Procurement Line

INSERT INTO store_schema.procurement_line (
    procurement_id,
    product_id,
    quantity,
    unit_price,
    created_at
)
SELECT
    pr.procurement_id,
    p.product_id,
    v.quantity,
    v.unit_cost,
    v.created_at
FROM (
    VALUES
        ('prc001', 'bosch', 'oven', 'series 6', 5, 2500.00, TIMESTAMP '2026-02-07 10:05:00'),
        ('prc002', 'lg', 'vacuum cleaner', 'cordzero', 8, 1300.00, TIMESTAMP '2026-02-16 11:05:00'),
        ('prc003', 'samsung', 'washing machine', 'eco bubble', 6, 1900.00, TIMESTAMP '2026-03-03 09:35:00'),
        ('prc004', 'whirlpool', 'air conditioner', 'inverter pro', 4, 2100.00, TIMESTAMP '2026-03-20 12:05:00'),
        ('prc005', 'philips', 'refrigerator', 'no frost', 3, 3400.00, TIMESTAMP '2026-04-05 14:05:00'),
        ('prc005', 'whirlpool', 'washing machine', 'eco', 7, 1700.00, TIMESTAMP '2026-04-22 16:05:00'),
        ('prc006', 'whirlpool', 'washing machine', 'eco', 7, 1700.00, TIMESTAMP '2026-02-28 16:05:00')
) AS v(procurement_number, brand_name, product_name, product_model, quantity, unit_cost, created_at)
JOIN store_schema.procurement pr
    ON pr.procurement_number = UPPER(v.procurement_number)
JOIN store_schema.brand b
    ON b.brand_name = UPPER(v.brand_name)
JOIN store_schema.product p
    ON p.brand_id = b.brand_id
   AND p.product_name = UPPER(v.product_name)
   AND p.product_model = UPPER(v.product_model)
ON CONFLICT (procurement_id, product_id) DO NOTHING
RETURNING *;

-- Table 11. Inventory Movement 

INSERT INTO store_schema.inventory_movement (
    product_id,
    employee_id,
    movement_type,
    quantity,
    movement_date,
    created_at
)
SELECT
    p.product_id,
    e.employee_id,
    UPPER(v.movement_type),
    v.quantity,
    v.movement_date,
    v.created_at
FROM (
    VALUES
        ('bosch', 'oven', 'series 6', 'elizabeth.moore@store.com', 'in', 5, TIMESTAMP '2026-02-07 10:10:00', TIMESTAMP '2026-02-07 10:10:00'),
        ('lg', 'vacuum cleaner', 'cordzero', 'elizabeth.moore@store.com', 'in', 8, TIMESTAMP '2026-02-16 11:10:00', TIMESTAMP '2026-02-16 11:10:00'),
        ('samsung', 'washing machine', 'eco bubble', 'elizabeth.moore@store.com', 'in', 6, TIMESTAMP '2026-03-03 09:40:00', TIMESTAMP '2026-03-03 09:40:00'),
        ('whirlpool', 'air conditioner', 'inverter pro', 'david.taylor@store.com', 'in', 4, TIMESTAMP '2026-03-20 12:10:00', TIMESTAMP '2026-03-20 12:10:00'),
        ('philips', 'refrigerator', 'no frost', 'david.taylor@store.com', 'in', 3, TIMESTAMP '2026-04-05 14:10:00', TIMESTAMP '2026-04-05 14:10:00'),
        ('whirlpool', 'washing machine', 'eco', 'elizabeth.moore@store.com', 'in', 7, TIMESTAMP '2026-04-22 16:10:00', TIMESTAMP '2026-04-22 16:10:00')
) AS v(brand_name, product_name, product_model, employee_email, movement_type, quantity, movement_date, created_at)
JOIN store_schema.brand b
    ON b.brand_name = UPPER(v.brand_name)
JOIN store_schema.product p
    ON p.brand_id = b.brand_id
   AND p.product_name = UPPER(v.product_name)
   AND p.product_model = UPPER(v.product_model)
JOIN store_schema.employee e
    ON e.employee_email = LOWER(v.employee_email)
WHERE NOT EXISTS (
    SELECT 1
    FROM store_schema.inventory_movement im
    WHERE im.product_id = p.product_id
      AND im.employee_id = e.employee_id
      AND im.movement_type = UPPER(v.movement_type)
      AND im.quantity = v.quantity
      AND im.movement_date = v.movement_date
)
RETURNING *;

-- Task 5.1.
-- Create a function that updates data in one of your tables. This function should take the following input arguments:
-- The primary key value of the row you want to update
-- The name of the column you want to update
-- The new value you want to set for the specified column
-- This function should be designed to modify the specified row in the table, updating the specified column with the new value.

CREATE OR REPLACE FUNCTION store_schema.update_product_column (
    p_product_id INT,
    p_column_name VARCHAR,
    p_new_value TEXT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_column_name NOT IN ('product_name', 'product_model', 'product_price') THEN
        RAISE EXCEPTION 'Column % is not allowed to be updated by this function.', p_column_name;
    END IF;

    IF p_column_name = 'product_price' THEN
        IF p_new_value::NUMERIC <= 0 THEN
            RAISE EXCEPTION 'Product price must be greater than 0.';
        END IF;

        UPDATE store_schema.product
        SET product_price = p_new_value::NUMERIC
        WHERE product_id = p_product_id;

    ELSIF p_column_name = 'product_name' THEN
        IF LENGTH(TRIM(p_new_value)) = 0 THEN
            RAISE EXCEPTION 'Product name cannot be empty.';
        END IF;

        UPDATE store_schema.product
        SET product_name = UPPER(TRIM(p_new_value))
        WHERE product_id = p_product_id;

    ELSIF p_column_name = 'product_model' THEN
        IF LENGTH(TRIM(p_new_value)) = 0 THEN
            RAISE EXCEPTION 'Product model cannot be empty.';
        END IF;

        UPDATE store_schema.product
        SET product_model = UPPER(TRIM(p_new_value))
        WHERE product_id = p_product_id;
    END IF;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Product with id % does not exist.', p_product_id;
    END IF;
END;
$$;

-- Test Cases

-- Succesfull operation (Expected)
SELECT store_schema.update_product_column(1, 'product_price', '3500.00');

-- Error (Expected)
SELECT store_schema.update_product_column(1, 'product_price', '0.00');

-- Succesfull operation (Expected)
SELECT store_schema.update_product_column(1, 'product_name', 'electric oven');

-- Error (Expected)
SELECT store_schema.update_product_column(1, 'product_name', '');

-- Succesfull operation (Expected)
SELECT store_schema.update_product_column(1, 'product_model', 'series 8');

-- Error (Expected)
SELECT store_schema.update_product_column(1, 'product_model', '');

SELECT * FROM store_schema.product p 
WHERE p.product_id = 1;

-- Task 5.2
-- Create a function that adds a new transaction to your transaction table. 
-- You can define the input arguments and output format. 
-- Make sure all transaction attributes can be set with the function (via their natural keys). 
-- The function does not need to return a value but should confirm the successful insertion of the new transaction.

CREATE OR REPLACE FUNCTION store_schema.add_inventory_movement (
    p_brand_name VARCHAR,
    p_product_name VARCHAR,
    p_product_model VARCHAR,
    p_employee_email VARCHAR,
    p_movement_type VARCHAR,
    p_quantity INT,
    p_movement_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    p_created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_id INT;
    v_employee_id INT;
BEGIN
    SELECT p.product_id
    INTO v_product_id
    FROM store_schema.product p
    JOIN store_schema.brand b
        ON b.brand_id = p.brand_id
    WHERE b.brand_name = UPPER(TRIM(p_brand_name))
      AND p.product_name = UPPER(TRIM(p_product_name))
      AND p.product_model = UPPER(TRIM(p_product_model));

    IF v_product_id IS NULL THEN
        RAISE EXCEPTION 'Product not found.';
    END IF;

    SELECT employee_id
    INTO v_employee_id
    FROM store_schema.employee
    WHERE employee_email = LOWER(TRIM(p_employee_email));

    IF v_employee_id IS NULL THEN
        RAISE EXCEPTION 'Employee not found.';
    END IF;

    INSERT INTO store_schema.inventory_movement (
        product_id,
        employee_id,
        movement_type,
        quantity,
        movement_date,
        created_at
    )
    VALUES (
        v_product_id,
        v_employee_id,
        UPPER(TRIM(p_movement_type)),
        p_quantity,
        p_movement_date,
        p_created_at
    );

    RETURN 'Inventory movement was inserted successfully.';
END;
$$;

-- Test Case

-- Succesfull operation (Expected)
SELECT store_schema.add_inventory_movement(
    'whirlpool',
    'washing machine',
    'eco',
    'elizabeth.moore@store.com',
    'in',
    2,
    TIMESTAMP '2026-04-24 18:30:00',
    TIMESTAMP '2026-04-24 18:30:00'
);

-- Error (Expected)
SELECT store_schema.add_inventory_movement(
    'bosch',
    'oven',
    'series 6',
    'elizabeth.moore@store.com',
    'in',
    2,
    TIMESTAMP '2026-04-24 18:30:00',
    TIMESTAMP '2026-04-24 18:30:00'
);

-- Task 6
-- Create a view that presents analytics for the most recently added quarter in your database. 
-- Ensure that the result excludes irrelevant fields such as surrogate keys and duplicate entries

-- NOTES:
-- Most recently added quarter would translate in Q2 (April, May, June)

CREATE OR REPLACE VIEW store_schema.sales_analytics AS
WITH latest_quarter AS (
    SELECT
        DATE_TRUNC('quarter', MAX(order_date)) AS quarter_start,
        DATE_TRUNC('quarter', MAX(order_date)) + INTERVAL '3 months' AS next_quarter_start
    FROM store_schema.customer_order
)
SELECT
    lq.quarter_start::DATE AS quarter_start_date,
    (lq.next_quarter_start - INTERVAL '1 day')::DATE AS quarter_end_date,
    c.category_name,
    b.brand_name,
    p.product_name,
    p.product_model,
    COUNT(DISTINCT co.order_number) AS total_orders,
    SUM(ol.quantity) AS total_units_sold,
    SUM(ol.line_total) AS total_sales_amount,
    ROUND(AVG(ol.unit_price), 2) AS average_unit_price
FROM store_schema.customer_order co
JOIN store_schema.order_line ol
    ON ol.order_id = co.order_id
JOIN store_schema.product p
    ON p.product_id = ol.product_id
JOIN store_schema.brand b
    ON b.brand_id = p.brand_id
JOIN store_schema.category c
    ON c.category_id = p.category_id
CROSS JOIN latest_quarter lq
WHERE co.order_date >= lq.quarter_start
  AND co.order_date < lq.next_quarter_start
GROUP BY
    lq.quarter_start,
    lq.next_quarter_start,
    c.category_name,
    b.brand_name,
    p.product_name,
    p.product_model;

SELECT *
FROM store_schema.sales_analytics;

-- Task 7
-- Create a read-only role for the manager. 
-- This role should have permission to perform SELECT queries on the database tables, and also be able to log in. 
-- Please ensure that you adhere to best practices for database security when defining this role

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_roles
        WHERE rolname = 'manager_role'
    ) THEN
        CREATE ROLE manager_role
        WITH LOGIN
        PASSWORD 'manager';
    END IF;
END $$;

SELECT *
FROM pg_roles
WHERE rolname = 'manager_role';

GRANT CONNECT ON DATABASE household_appliances_store
TO manager_role;

GRANT USAGE ON SCHEMA store_schema
TO manager_role;

GRANT SELECT ON ALL TABLES IN SCHEMA store_schema
TO manager_role;

SELECT *
FROM information_schema.role_table_grants
WHERE grantee  = 'manager_role';

-- Example
SET ROLE manager_role;

-- Succesful operation (expected)
SELECT *
FROM store_schema.product;

-- Denied acces error (expected)
UPDATE store_schema.product
SET product_price = 9999.99
WHERE UPPER(product_name) LIKE '%OVEN%';

RESET ROLE;
