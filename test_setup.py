#!/usr/bin/env python3
"""
Test script to verify the Healthcare Research Dashboard setup
This script checks if all required files exist and if Python dependencies can be imported.
"""

import os
import sys
import importlib

def check_files():
    """Check if all required files exist"""
    print("Checking required files...")
    
    required_files = [
        "index.html",
        "db_connector.py",
        "requirements.txt",
        "load-data-db.sql",
        "repoting_queries.sql",
        "README.md",
        "deploy.py",
        ".github/workflows/deploy.yml"
    ]
    
    missing_files = []
    for file in required_files:
        if os.path.exists(file):
            print(f"  ✓ {file}")
        else:
            print(f"  ✗ {file} (MISSING)")
            missing_files.append(file)
    
    return len(missing_files) == 0

def check_python_dependencies():
    """Check if Python dependencies can be imported"""
    print("\nChecking Python dependencies...")
    
    with open("requirements.txt", "r") as f:
        dependencies = [line.strip() for line in f.readlines() if line.strip() and not line.startswith("#")]
    
    missing_deps = []
    for dep in dependencies:
        # Handle special cases for package names that differ from import names
        import_name = dep
        if dep == "psycopg2-binary":
            import_name = "psycopg2"
        
        try:
            importlib.import_module(import_name)
            print(f"  ✓ {dep}")
        except ImportError:
            print(f"  ✗ {dep} (NOT INSTALLED)")
            missing_deps.append(dep)
    
    return len(missing_deps) == 0

def check_directories():
    """Check if required directories exist"""
    print("\nChecking directories...")
    
    required_dirs = [
        "Datasets"
    ]
    
    missing_dirs = []
    for directory in required_dirs:
        if os.path.exists(directory) and os.path.isdir(directory):
            print(f"  ✓ {directory}")
        else:
            print(f"  ✗ {directory} (MISSING)")
            missing_dirs.append(directory)
    
    return len(missing_dirs) == 0

def main():
    """Main test function"""
    print("Healthcare Research Dashboard Setup Test")
    print("=" * 50)
    
    files_ok = check_files()
    deps_ok = check_python_dependencies()
    dirs_ok = check_directories()
    
    print("\n" + "=" * 50)
    if files_ok and deps_ok and dirs_ok:
        print("✓ All checks passed! Your setup is ready.")
        print("\nNext steps:")
        print("1. Set up your PostgreSQL database")
        print("2. Load your data using load-data-db.sql")
        print("3. Update database connection in db_connector.py")
        print("4. Run 'python db_connector.py' to generate dashboard data")
        print("5. Open index.html in your browser to view the dashboard")
        return True
    else:
        print("✗ Some checks failed. Please review the issues above.")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)