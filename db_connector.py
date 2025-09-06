import psycopg2
import json
import pandas as pd
import sys
from datetime import datetime

# Database connection parameters - update these to match your local setup
DB_CONFIG = {
    'host': 'localhost',
    'database': 'phd-project',
    'user': 'admin',
    'password': 'phdwork',
    'port': '5432'
}

def connect_to_db():
    """Establish connection to PostgreSQL database"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except Exception as e:
        print(f"Error connecting to database: {e}")
        return None

def execute_query(conn, query):
    """Execute a SQL query and return results as DataFrame"""
    try:
        df = pd.read_sql_query(query, conn)
        return df
    except Exception as e:
        print(f"Error executing query: {e}")
        return None

def run_all_queries():
    """Run all queries from reporting_queries.sql and save results"""
    conn = connect_to_db()
    if not conn:
        print("Failed to connect to database")
        return
    
    # Define queries with names for dashboard sections
    queries = {
        "kpi_total_patients": """
            -- Using updated logic from reporting_queries.sql
            SELECT
                COUNT(DISTINCT patient_id) as total_patients,
                'All Time' as period
            FROM synthetic_ehr
            UNION ALL
            SELECT
                COUNT(DISTINCT patient_id) as total_patients,
                'Last 30 Days' as period
            FROM synthetic_ehr
            WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
        """,
        
        "kpi_active_trials": """
            -- Using updated logic from reporting_queries.sql
            SELECT
                COUNT(*) as active_trials,
                COUNT(CASE WHEN phase = 'Phase I' THEN 1 END) as phase_1,
                COUNT(CASE WHEN phase = 'Phase II' THEN 1 END) as phase_2,
                COUNT(CASE WHEN phase = 'Phase III' THEN 1 END) as phase_3,
                COUNT(CASE WHEN phase = 'Phase IV' THEN 1 END) as phase_4
            FROM clinical_trials
            WHERE status IN ('Active', 'Recruiting', 'Enrolling')
        """,
        
        "kpi_safety_incidents": """
            -- Using updated logic from reporting_queries.sql
            SELECT
                COUNT(*) as total_incidents,
                COUNT(CASE WHEN serious = false THEN 1 END) as mild_incidents,
                COUNT(CASE WHEN serious = true THEN 1 END) as moderate_incidents,
                0 as severe_incidents,
                0 as critical_incidents,
                ROUND(AVG(CASE WHEN serious = true THEN 8 ELSE 2 END), 2) as avg_severity_score
            FROM drug_safety
            WHERE report_date >= CURRENT_DATE - INTERVAL '30 days'
        """,
        
        "kpi_drug_portfolio": """
            -- Using updated logic from Query 6: Comprehensive Drug Portfolio Analysis in reporting_queries.sql
            SELECT
                COUNT(DISTINCT don.drug_name) as total_drugs_studied,
                COUNT(DISTINCT don.drug_class) as drug_categories,
                COUNT(DISTINCT CASE WHEN don.approved = true THEN don.drug_name END) as approved_drugs,
                COUNT(DISTINCT ds.drug_name) as under_review
            FROM drug_ontology don
            LEFT JOIN drug_safety ds ON don.drug_id = ds.drug_id
        """,
        
        "enrollment_trends": """
            -- Keeping existing logic as there's no direct equivalent in repoting_queries.sql
            SELECT
                DATE_TRUNC('month', start_date) as enrollment_month,
                TO_CHAR(DATE_TRUNC('month', start_date), 'Mon YYYY') as month_label,
                COUNT(*) as new_enrollments,
                COUNT(DISTINCT trial_id) as active_trials_that_month,
                ROUND(COUNT(*)::numeric / COUNT(DISTINCT trial_id), 1) as avg_enrollment_per_trial
            FROM clinical_trials
            WHERE start_date >= CURRENT_DATE - INTERVAL '12 months'
                AND start_date IS NOT NULL
            GROUP BY DATE_TRUNC('month', start_date)
            ORDER BY enrollment_month
        """,
        
        "enrollment_by_phase": """
            -- Keeping existing logic as there's no direct equivalent in repoting_queries.sql
            SELECT
                phase,
                COUNT(*) as total_enrolled,
                COUNT(DISTINCT trial_id) as number_of_trials,
                ROUND(AVG(CASE WHEN phase = 'Phase I' THEN 150 WHEN phase = 'Phase II' THEN 200 WHEN phase = 'Phase III' THEN 250 WHEN phase = 'Phase IV' THEN 500 ELSE 100 END), 0) as avg_target_enrollment,
                ROUND(
                    (COUNT(*)::numeric / NULLIF(SUM(CASE WHEN phase = 'Phase I' THEN 150 WHEN phase = 'Phase II' THEN 200 WHEN phase = 'Phase III' THEN 250 WHEN phase = 'Phase IV' THEN 500 ELSE 100 END), 0)) * 100,
                    1
                ) as enrollment_rate_percent
            FROM clinical_trials
            WHERE start_date IS NOT NULL
            GROUP BY phase
            ORDER BY
                CASE phase
                    WHEN 'Phase I' THEN 1
                    WHEN 'Phase II' THEN 2
                    WHEN 'Phase III' THEN 3
                    WHEN 'Phase IV' THEN 4
                END
        """,
        
        "safety_timeline": """
            -- Using updated logic from Query 8: Time-based Trend Analysis in reporting_queries.sql
            SELECT
                DATE_TRUNC('quarter', report_date) as incident_week,
                TO_CHAR(DATE_TRUNC('quarter', report_date), 'YYYY-Q') as week_label,
                COUNT(*) as total_incidents,
                COUNT(CASE WHEN serious = false THEN 1 END) as mild_events,
                COUNT(CASE WHEN serious = true THEN 1 END) as moderate_events,
                COUNT(CASE WHEN serious = true THEN 1 END) as severe_events,
                0 as critical_events,
                ROUND(AVG(CASE WHEN serious = true THEN 8 ELSE 2 END), 2) as weekly_avg_severity
            FROM drug_safety
            WHERE report_date IS NOT NULL
                AND report_date >= '2020-01-01'
            GROUP BY DATE_TRUNC('quarter', report_date)
            ORDER BY incident_week
        """,
        
        "recent_trials": """
            -- Keeping existing logic as there's no direct equivalent in repoting_queries.sql
            SELECT DISTINCT ON (trial_id)
                trial_id,
                intervention as drug_name,
                phase,
                status,
                0 as enrolled_patients,
                CASE WHEN phase = 'Phase I' THEN 150 WHEN phase = 'Phase II' THEN 200 WHEN phase = 'Phase III' THEN 250 WHEN phase = 'Phase IV' THEN 500 ELSE 100 END as target_enrollment,
                0 as enrollment_progress,
                start_date,
                end_date as expected_completion_date,
                CASE
                    WHEN status = 'Active' THEN 'success'
                    WHEN status = 'Completed' THEN 'info'
                    WHEN status = 'Suspended' THEN 'warning'
                    WHEN status = 'Terminated' THEN 'danger'
                    ELSE 'secondary'
                END as status_class
            FROM clinical_trials
            ORDER BY trial_id, start_date DESC
        """,
        
        "recent_incidents": """
            -- Using updated logic from Query 5: Drug Safety Red Flags in reporting_queries.sql
            SELECT
                report_date as incident_date,
                drug_name,
                CASE WHEN serious = false THEN 'mild' ELSE 'moderate' END as severity_level,
                serious as severity_score,
                adverse_event as incident_description,
                adverse_event as phase,
                CASE
                    WHEN serious = false THEN 'success'
                    WHEN serious = true THEN 'warning'
                    ELSE 'secondary'
                END as severity_class
            FROM drug_safety
            WHERE adverse_event IN ('Death', 'Liver Damage', 'Heart Attack', 'Stroke')
            ORDER BY report_date DESC
            LIMIT 15
        """,
        
        "demographics": """
            -- Using updated logic from Query 7: Patient Demographics and Outcomes by Condition in reporting_queries.sql
            SELECT
                CASE
                    WHEN age < 18 THEN 'Pediatric'
                    WHEN age BETWEEN 18 AND 65 THEN 'Adult'
                    ELSE 'Elderly'
                END as age_group,
                gender,
                COUNT(*) as patient_count,
                ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER() * 100, 1) as percentage,
                ROUND(AVG(age), 1) as avg_age_in_group
            FROM synthetic_ehr
            WHERE age IS NOT NULL AND gender IS NOT NULL
            GROUP BY
                CASE
                    WHEN age < 18 THEN 'Pediatric'
                    WHEN age BETWEEN 18 AND 65 THEN 'Adult'
                    ELSE 'Elderly'
                END,
                gender
            ORDER BY
                CASE
                    WHEN age < 18 THEN 'Pediatric'
                    WHEN age BETWEEN 18 AND 65 THEN 'Adult'
                    ELSE 'Elderly'
                END,
                gender
        """
    }
    
    # Execute all queries and store results
    results = {}
    for name, query in queries.items():
        print(f"Executing query: {name}")
        df = execute_query(conn, query)
        if df is not None:
            # Convert DataFrame to JSON-serializable format
            results[name] = df.to_dict('records')
        else:
            results[name] = []
            print(f"Failed to execute query: {name}")
    
    # Save results to JSON file
    with open('dashboard_data.json', 'w') as f:
        json.dump(results, f, default=str, indent=2)
    
    print("All queries executed and data saved to dashboard_data.json")
    conn.close()

if __name__ == "__main__":
    run_all_queries()