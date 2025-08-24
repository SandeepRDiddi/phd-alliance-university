#!/usr/bin/env python3
"""
Deployment script for Healthcare Research Dashboard
This script automates the process of generating dashboard data and preparing files for GitHub Pages deployment.
"""

import os
import subprocess
import shutil
import sys
import json
from datetime import datetime

def run_db_connector():
    """Run the database connector script to generate dashboard data"""
    print("Running database connector to generate dashboard data...")
    try:
        result = subprocess.run([sys.executable, "db_connector.py"], 
                              capture_output=True, text=True, check=True)
        print("Database connector executed successfully!")
        print(result.stdout)
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error running database connector: {e}")
        print(f"Error output: {e.stderr}")
        return False

def create_docs_directory():
    """Create docs directory for GitHub Pages deployment"""
    print("Creating docs directory for GitHub Pages...")
    if os.path.exists("docs"):
        shutil.rmtree("docs")
    
    os.makedirs("docs")
    return True

def copy_files_to_docs():
    """Copy necessary files to docs directory"""
    print("Copying files to docs directory...")
    
    # Files to copy
    files_to_copy = [
        "index.html",
        "dashboard.css",
        "dashboard_data.json",
        "README.md"
    ]
    
    for file in files_to_copy:
        if os.path.exists(file):
            shutil.copy2(file, "docs/")
            print(f"Copied {file} to docs/")
        else:
            print(f"Warning: {file} not found")
    
    # Create a simple redirect if index.html doesn't exist in root
    if not os.path.exists("index.html"):
        with open("docs/index.html", "w") as f:
            f.write("""
<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="refresh" content="0; url=./index.html" />
</head>
<body>
    <p>Redirecting to dashboard...</p>
</body>
</html>
            """)
    
    return True

def create_github_pages_config():
    """Create static.json for GitHub Pages configuration"""
    print("Creating GitHub Pages configuration...")
    
    config = {
        "root": "docs/",
        "clean_urls": True,
        "routes": {
            "/**": "index.html"
        }
    }
    
    with open("docs/static.json", "w") as f:
        json.dump(config, f, indent=2)
    
    # Also create a .nojekyll file to bypass Jekyll processing
    with open("docs/.nojekyll", "w") as f:
        pass
    
    return True

def main():
    """Main deployment function"""
    print("Healthcare Research Dashboard Deployment Script")
    print("=" * 50)
    
    # Step 1: Run database connector
    if not run_db_connector():
        print("Failed to generate dashboard data. Exiting.")
        return False
    
    # Step 2: Create docs directory
    if not create_docs_directory():
        print("Failed to create docs directory. Exiting.")
        return False
    
    # Step 3: Copy files to docs
    if not copy_files_to_docs():
        print("Failed to copy files to docs directory. Exiting.")
        return False
    
    # Step 4: Create GitHub Pages configuration
    if not create_github_pages_config():
        print("Failed to create GitHub Pages configuration. Exiting.")
        return False
    
    print("\nDeployment preparation completed successfully!")
    print("\nTo deploy to GitHub Pages:")
    print("1. Commit and push the docs folder to your GitHub repository")
    print("2. Go to your repository settings on GitHub")
    print("3. Under 'Pages', select 'Deploy from a branch'")
    print("4. Choose 'main' branch and '/docs' folder")
    print("5. Click 'Save' - your site will be deployed at https://yourusername.github.io/your-repo-name/")
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)