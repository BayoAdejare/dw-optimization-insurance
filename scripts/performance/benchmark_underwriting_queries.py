import snowflake.connector
import time
from tabulate import tabulate

# Snowflake connection parameters
ACCOUNT = 'usr_account'
USER = 'usr_username'
PASSWORD = 'usr_password'
WAREHOUSE = 'policy_data_warehouse'
DATABASE = 'insurance_db'
SCHEMA = 'public'

# Benchmark queries
QUERIES = {
    "Count policies by type and status": """
        SELECT policy_type, policy_status, COUNT(*) as policy_count
        FROM policies
        GROUP BY 1, 2
        ORDER BY 1, 2
    """,
    "Avg premium by policy type (last year)": """
        SELECT policy_type, AVG(premium_amount) as avg_premium
        FROM policies
        WHERE effective_date >= DATEADD(year, -1, CURRENT_DATE())
        GROUP BY 1
        ORDER BY 2 DESC
    """,
    "Identify high-risk policies": """
        SELECT policy_number, policy_type, coverage_limit, premium_amount,
               coverage_limit / premium_amount as risk_ratio
        FROM policies
        WHERE policy_status = 'ACTIVE'
        AND coverage_limit / premium_amount > 1000
        ORDER BY risk_ratio DESC
        LIMIT 100
    """,
    "Customer policy history": """
        SELECT c.customer_id, c.last_name, c.first_name, 
               p.policy_number, p.policy_type, p.effective_date, p.expiration_date,
               COUNT(cl.claim_id) as claim_count
        FROM customers c
        JOIN policies p ON c.customer_id = p.customer_id
        LEFT JOIN claims cl ON p.policy_number = cl.policy_number
        WHERE c.customer_id = '12345'  -- Replace with an actual customer_id
        GROUP BY 1, 2, 3, 4, 5, 6, 7
        ORDER BY p.effective_date DESC
    """,
    "Policy renewal candidates": """
        SELECT p.policy_number, p.policy_type, p.expiration_date, 
               c.last_name, c.first_name, c.risk_score
        FROM policies p
        JOIN customers c ON p.customer_id = c.customer_id
        WHERE p.expiration_date BETWEEN CURRENT_DATE() AND DATEADD(month, 1, CURRENT_DATE())
        AND p.policy_status = 'ACTIVE'
        AND c.risk_score < 50
        ORDER BY p.expiration_date
    """
}

def run_benchmark(conn, query):
    cursor = conn.cursor()
    start_time = time.time()
    cursor.execute(query)
    end_time = time.time()
    execution_time = end_time - start_time
    cursor.close()
    return execution_time

def main():
    try:
        conn = snowflake.connector.connect(
            account=ACCOUNT,
            user=USER,
            password=PASSWORD,
            warehouse=WAREHOUSE,
            database=DATABASE,
            schema=SCHEMA
        )
        
        print("Connected to Snowflake successfully.")
        
        results = []
        for name, query in QUERIES.items():
            execution_time = run_benchmark(conn, query)
            results.append([name, execution_time])
            print(f"Executed query: {name}")
        
        print("\nBenchmark Results:")
        print(tabulate(results, headers=["Query Name", "Execution Time (s)"], tablefmt="grid"))
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if 'conn' in locals():
            conn.close()
            print("Snowflake connection closed.")

if __name__ == "__main__":
    main()
