-- Snowflake automatically creates and manages indexes.
-- Adding to claims table clustering keys and search optimization.

-- Create a clustering key on frequently filtered/joined columns
ALTER TABLE claims CLUSTER BY (policy_number, claim_date);

-- Enable search optimization for text-based searches
ALTER TABLE claims ADD SEARCH OPTIMIZATION ON claimant_last_name, claimant_first_name;

-- Create a materialized view for common aggregations
CREATE MATERIALIZED VIEW mv_claims_summary AS
SELECT 
    policy_type,
    claim_type,
    DATE_TRUNC('month', claim_date) AS claim_month,
    COUNT(*) AS claim_count,
    SUM(claim_amount) AS total_claim_amount
FROM claims
GROUP BY 1, 2, 3;

-- Optimize warehouse for query performance (adjust size as needed)
ALTER WAREHOUSE claims_warehouse SET 
    WAREHOUSE_SIZE = 'LARGE'
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 3
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE;
