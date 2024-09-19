-- Create a clustering key on frequently filtered/joined columns
ALTER TABLE customers CLUSTER BY (customer_id, last_name, zip_code);

-- Enable search optimization for text-based searches
ALTER TABLE customers ADD SEARCH OPTIMIZATION ON last_name, first_name, email;

-- Create a materialized view for common customer aggregations
CREATE MATERIALIZED VIEW mv_customer_summary AS
SELECT 
    zip_code,
    DATE_TRUNC('year', date_of_birth) AS birth_year,
    gender,
    COUNT(*) AS customer_count,
    AVG(lifetime_value) AS avg_lifetime_value
FROM customers
GROUP BY 1, 2, 3;

-- Create a secure view for sensitive customer information
CREATE SECURE VIEW vw_customer_sensitive AS
SELECT 
    customer_id,
    CASE 
        WHEN current_role() IN ('CUSTOMER_SERVICE_REP', 'CLAIMS_ADJUSTER') 
        THEN last_name || ', ' || first_name 
        ELSE '****'
    END AS customer_name,
    CASE 
        WHEN current_role() = 'CLAIMS_ADJUSTER' 
        THEN date_of_birth 
        ELSE NULL
    END AS date_of_birth,
    zip_code
FROM customers;

-- Optimize warehouse for customer data queries (adjust size as needed)
ALTER WAREHOUSE customer_data_warehouse SET 
    WAREHOUSE_SIZE = 'MEDIUM'
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 2
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE;
