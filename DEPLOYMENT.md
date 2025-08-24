# Deployment Guide for Healthcare Research Dashboard

This guide explains how to deploy the Healthcare Research Dashboard to various free hosting platforms.

## Prerequisites

Before deploying, make sure you have:

1. Run the deployment preparation script:
   ```bash
   python deploy.py
   ```
   
   This will create a `docs/` directory with all necessary files for deployment.

2. A free account on your chosen deployment platform.

## Deployment Options

### 1. GitHub Pages (Recommended)

GitHub Pages is the easiest option since it's already partially set up in this project.

#### Steps:

1. Create a GitHub repository for your project (if you haven't already)
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
5. Choose "main" branch and "/docs" folder
6. Click "Save" - your site will be deployed at `https://yourusername.github.io/your-repo-name/`

### 2. Netlify

Netlify is a popular static site hosting platform with a generous free tier.

#### Steps:

1. Go to [netlify.com](https://netlify.com) and sign up for a free account
2. Install the Netlify CLI:
   ```bash
   npm install -g netlify-cli
   ```
3. Login to Netlify:
   ```bash
   netlify login
   ```
4. Deploy your site:
   ```bash
   # Navigate to your project directory
   cd phd-alliance-university
   
   # Deploy the docs folder
   netlify deploy --dir=docs --prod
   ```
   
   Or alternatively, you can drag and drop the `docs` folder to Netlify's web interface.

### 3. Vercel

Vercel is another excellent option for static site hosting with a good free tier.

#### Steps:

1. Go to [vercel.com](https://vercel.com) and sign up for a free account
2. Install the Vercel CLI:
   ```bash
   npm install -g vercel
   ```
3. Login to Vercel:
   ```bash
   vercel login
   ```
4. Deploy your site:
   ```bash
   # Navigate to your project directory
   cd phd-alliance-university
   
   # Deploy the docs folder
   vercel --prod docs
   ```

### 4. Firebase Hosting

Firebase Hosting is Google's static hosting service with a generous free tier.

#### Steps:

1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```
2. Login to Firebase:
   ```bash
   firebase login
   ```
3. Initialize Firebase in your project:
   ```bash
   # Navigate to your project directory
   cd phd-alliance-university
   
   # Initialize Firebase
   firebase init hosting
   ```
4. Configure Firebase to use the `docs` folder:
   - When prompted, select your Firebase project
   - Set the public directory to `docs`
   - Configure as a single-page app: No
   - Set up automatic builds and deploys with GitHub? No

5. Deploy your site:
   ```bash
   firebase deploy --only hosting
   ```

## Notes

1. The dashboard is a static site that only requires HTML, CSS, and JavaScript to run
2. All data is pre-generated and stored in `dashboard_data.json`
3. No server-side processing is required at runtime
4. The large size of `dashboard_data.json` (16MB) may affect loading times on some platforms
5. For better performance, consider optimizing the data or implementing pagination in future versions

## Troubleshooting

If your deployed dashboard isn't loading correctly:

1. Check that all files were uploaded correctly
2. Verify that `dashboard_data.json` is accessible
3. Check the browser console for any errors
4. Ensure that your deployment platform isn't blocking large files
5. Some platforms may require additional configuration for large JSON files

For any issues, please check the browser's developer console for error messages and consult the documentation for your chosen deployment platform.