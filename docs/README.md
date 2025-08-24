# Healthcare Research Dashboard

A comprehensive interactive dashboard for clinical trials and drug safety analytics. This dashboard connects to a local PostgreSQL database, runs analytical queries, and visualizes key performance indicators for healthcare research.

**Note**: This dashboard requires a local PostgreSQL database to be set up with the appropriate schema and data. If you don't have PostgreSQL installed or don't have access to the database, the dashboard will automatically fall back to using sample data for demonstration purposes.

## Features

- **KPI Dashboard**: Overview of patients, trials, safety incidents, and drug portfolio
- **Analytics Charts**: Enrollment trends, safety timelines, and patient demographics
- **Detailed Reports**: Recent trials and safety incidents tables
- **Responsive Design**: Works on desktop and mobile devices
- **GitHub Pages Deployment**: Easy static deployment

## Prerequisites

- Python 3.7+
- PostgreSQL database
- Node.js and npm (for GitHub Pages deployment)

## Setup Instructions

### 1. Database Setup

1. Install PostgreSQL on your local machine
2. Create a new database:
   ```sql
   CREATE DATABASE medical_data;
   ```
3. Run the database schema setup:
   ```bash
   psql -U your_username -d medical_data -f load-data-db.sql
   ```
4. Load your data into the database (adjust file paths in the script):
   ```bash
   psql -U your_username -d medical_data -f load-data-db.sql
   ```

### 2. Python Environment Setup

1. Create a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. Install required packages:
   ```bash
   pip install -r requirements.txt
   ```

3. Update database connection parameters in `db_connector.py`:
   ```python
   DB_CONFIG = {
       'host': 'localhost',
       'database': 'medical_data',
       'user': 'your_username',
       'password': 'your_password',
       'port': '5432'
   }
   ```

### 3. Generate Dashboard Data

Run the Python script to execute queries and generate JSON data:
```bash
python db_connector.py
```

This will create a `dashboard_data.json` file with all the query results.

### 4. View the Dashboard

Open `index.html` in your web browser to view the dashboard.

## GitHub Pages Deployment

### Option 1: Manual Deployment

1. Create a GitHub repository for your project
2. Push your files to the repository:
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/yourusername/your-repo-name.git
   git push -u origin main
   ```
3. Go to your repository settings on GitHub
4. Under "Pages", select "Deploy from a branch"
5. Choose "main" branch and "/ (root)" folder
6. Click "Save" - your site will be deployed at `https://yourusername.github.io/your-repo-name/`

### Option 2: GitHub CLI Deployment

1. Install GitHub CLI if you haven't already
2. Create and deploy:
   ```bash
   gh repo create your-repo-name --public
   git push origin main
   gh deploy
   ```

## Project Structure

```
├── index.html              # Main dashboard HTML file
├── db_connector.py         # Python script to connect to database and run queries
├── requirements.txt        # Python dependencies
├── load-data-db.sql        # Database schema and data loading scripts
├── metadata.sql            # Dataset metadata catalog
├── repoting_queries.sql    # Analytical SQL queries
├── dashboard_data.json     # Generated data (after running db_connector.py)
├── Datasets/               # CSV data files
│   ├── clinical_trials_50k.csv
│   ├── drug_ontology_50k.csv
│   ├── drug_safety_50k.csv
│   └── synthetic_ehr_50k.csv
└── README.md
```

## Customization

### Modifying Queries

To modify the analytical queries, edit `repoting_queries.sql` and update the `queries` dictionary in `db_connector.py` accordingly.

### Styling

The dashboard uses Bootstrap 5 for styling. You can customize the appearance by modifying the CSS in the `<style>` section of `index.html`.

### Adding New Charts

1. Add a new query to the `queries` dictionary in `db_connector.py`
2. Create a new chart function in the JavaScript section of `index.html`
3. Add the chart container HTML in the appropriate section

## Troubleshooting

### Database Connection Issues

- Verify PostgreSQL is running:
  - On macOS: `brew services start postgresql` or check in System Preferences
  - On Windows: Check Services or run `net start postgresql`
  - On Linux: `sudo systemctl start postgresql`
- Check database credentials in `db_connector.py`
- Ensure the database exists and your user has proper permissions
- Try connecting with psql directly: `psql -h localhost -p 5432 -U admin -d phd-project`
- If you get authentication errors, you may need to update pg_hba.conf to allow md5 authentication

### Missing Data

- Verify CSV files are in the correct location
- Check file paths in `load-data-db.sql`
- Ensure data was properly loaded into the database

### Chart Display Issues

- Check browser console for JavaScript errors
- Verify `dashboard_data.json` was generated correctly
- Ensure all required data fields exist in the JSON

### Missing Data

- Verify CSV files are in the correct location
- Check file paths in `load-data-db.sql`
- Ensure data was properly loaded into the database

### Chart Display Issues

- Check browser console for JavaScript errors
- Verify `dashboard_data.json` was generated correctly
- Ensure all required data fields exist in the JSON

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built with Chart.js for data visualization
- Styled with Bootstrap 5
- Database powered by PostgreSQL