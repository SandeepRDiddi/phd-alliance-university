#!/usr/bin/env python3
"""
Simple script to test database connection
"""

import psycopg2

# Database connection parameters
DB_CONFIG = {
    'host': 'localhost',
    'database': 'phd-project',
    'user': 'admin',
    'password': 'phdwork',
    'port': '5432'
}

def test_connection():
    """Test database connection"""
    try:
        print("Attempting to connect to database...")
        conn = psycopg2.connect(**DB_CONFIG)
        print("✓ Successfully connected to the database!")
        
        # Test with a simple query
        cursor = conn.cursor()
        cursor.execute("SELECT version();")
        version = cursor.fetchone()
        print(f"PostgreSQL version: {version[0]}")
        
        # Check if tables exist
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
            ORDER BY table_name;
        """)
        tables = cursor.fetchall()
        print(f"\nTables in database:")
        for table in tables:
            print(f"  - {table[0]}")
        
        cursor.close()
        conn.close()
        return True
        
    except psycopg2.OperationalError as e:
        print(f"✗ Operational error: {e}")
        return False
    except psycopg2.Error as e:
        print(f"✗ Database error: {e}")
        return False
    except Exception as e:
        print(f"✗ Unexpected error: {e}")
        return False

if __name__ == "__main__":
    success = test_connection()
    if success:
        print("\n✓ Database connection test passed!")
    else:
        print("\n✗ Database connection test failed!")
        print("\nTroubleshooting tips:")
        print("1. Ensure PostgreSQL is running")
        print("2. Verify database 'phd-project' exists")
        print("3. Check if user 'admin' exists and has proper permissions")
        print("4. Verify the password is correct")