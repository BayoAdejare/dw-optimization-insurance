-- Create a clustering key on frequently filtered/joined columns
ALTER TABLE policies CLUSTER BY (policy_number, customer_id, policy_type, effective_date);

-- Enable search optimization for text-based searches
ALTER TABLE policies ADD SEARCH OPTIMIZATION ON policy_number, insured_name;

-- Create a materialized view for common policy aggregations
CREATE MATERIALIZED VIEW mv_policy_summary AS
SELECT 
    policy_type,
    DATE_TRUNC('month', effective_date) AS effective_month,
    COUNT(*) AS policy_count,
    SUM(premium_amount) AS total_premium,
    AVG(coverage_limit) AS avg_coverage_limit
FROM policies
WHERE policy_status = 'ACTIVE'
GROUP BY 1, 2;

-- Create a secure view for policy information
CREATE SECURE VIEW vw_policy_details AS
SELECT 
    p.policy_number,
    p.policy_type,
    p.effective_date,
    p.expiration_date,
    p.premium_amount,
    p.coverage_limit,
    CASE 
        WHEN current_role() IN ('UNDERWRITER', 'CLAIMS_ADJUSTER') 
        THEN c.last_name || ', ' || c.first_name 
        ELSE '****'
    END AS insured_name,
    c.zip_code
FROM policies p
JOIN customers c ON p.customer_id = c.customer_id;

-- Optimize warehouse for policy data queries (adjust size as needed)
ALTER WAREHOUSE policy_data_warehouse SET 
    WAREHOUSE_SIZE = 'MEDIUM'
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 3
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE;

-- Create a task to refresh the materialized view daily
CREATE OR REPLACE TASK refresh_policy_summary
WAREHOUSE = policy_data_warehouse
SCHEDULE = 'USING CRON 0 1 * * * America/New_York'
AS
CALL SYSTEM$REFRESH_MATERIALIZED_VIEW('mv_policy_summary');
