-- Seed Data for CI/CD Demo
-- Run this after initial deployment to populate sample data

USE DATABASE CICD_DEMO_PROD;
USE SCHEMA RAW;

-- Insert sample customers
INSERT INTO CUSTOMERS (CUSTOMER_ID, CUSTOMER_NAME, EMAIL, REGION)
VALUES 
    (1, 'Acme Corporation', 'orders@acme.com', 'North America'),
    (2, 'Global Industries', 'procurement@globalind.com', 'Europe'),
    (3, 'Tech Innovations', 'buying@techinno.com', 'Asia Pacific'),
    (4, 'Metro Building Services', 'facilities@metrobuild.com', 'North America'),
    (5, 'Continental Elevators', 'supply@contelev.com', 'Europe'),
    (6, 'Summit Properties', 'maintenance@summitprop.com', 'North America'),
    (7, 'Pacific Towers', 'ops@pactowers.com', 'Asia Pacific'),
    (8, 'Urban Development Co', 'projects@urbandev.com', 'North America'),
    (9, 'EuroLift Services', 'service@eurolift.com', 'Europe'),
    (10, 'Skyline Facilities', 'admin@skylinefac.com', 'Asia Pacific');

-- Insert sample orders
INSERT INTO ORDERS (ORDER_ID, CUSTOMER_ID, ORDER_DATE, ORDER_AMOUNT, STATUS)
VALUES 
    (1001, 1, '2025-12-01', 15000.00, 'COMPLETED'),
    (1002, 1, '2025-12-15', 8500.00, 'COMPLETED'),
    (1003, 2, '2025-12-03', 22000.00, 'COMPLETED'),
    (1004, 3, '2025-12-05', 12500.00, 'COMPLETED'),
    (1005, 4, '2025-12-10', 45000.00, 'COMPLETED'),
    (1006, 5, '2025-12-12', 18000.00, 'COMPLETED'),
    (1007, 2, '2025-12-18', 9500.00, 'SHIPPED'),
    (1008, 6, '2025-12-20', 32000.00, 'SHIPPED'),
    (1009, 7, '2025-12-22', 28000.00, 'PROCESSING'),
    (1010, 8, '2025-12-28', 16500.00, 'PROCESSING'),
    (1011, 1, '2026-01-05', 11000.00, 'PENDING'),
    (1012, 9, '2026-01-08', 27500.00, 'PENDING'),
    (1013, 10, '2026-01-10', 19000.00, 'PENDING'),
    (1014, 3, '2026-01-15', 35000.00, 'PENDING'),
    (1015, 4, '2026-01-20', 42000.00, 'PENDING');

-- Insert sample products
INSERT INTO PRODUCTS (PRODUCT_ID, PRODUCT_NAME, CATEGORY, UNIT_PRICE)
VALUES 
    (101, 'Elevator Maintenance Kit', 'Maintenance', 2500.00),
    (102, 'Control Panel Upgrade', 'Electronics', 8500.00),
    (103, 'Safety Inspection Service', 'Services', 1500.00),
    (104, 'Motor Assembly', 'Components', 12000.00),
    (105, 'Door Mechanism', 'Components', 3500.00);

-- Verify data
SELECT 'Customers' AS table_name, COUNT(*) AS row_count FROM CUSTOMERS
UNION ALL
SELECT 'Orders', COUNT(*) FROM ORDERS
UNION ALL
SELECT 'Products', COUNT(*) FROM PRODUCTS;
