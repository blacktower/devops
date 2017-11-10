# WordPress DevOps
Teaching myself how to build a bootstrap for building WordPress infrastructure on multiple cloud platforms. Targeting Ubunto Xenial on AWS and Debian Jessie on Google

## Google Cloud
Using the admin console:
1. Enable Goolge Cloud SQL API (Go to API Manager -> Enable API -> Google Cloud SQL API)
2. Create the Cloud SQL instance
  - Save the Instance connection name for the compute engine
  - Add the databae name 'wordpress'
2. Create the Compute Engine
  - Copy contents of bootstrap.sh into Startup Script
  - Add the metadata field 'sqlproxy':
    - key = sqlproxy 
    - value={Cloud SQL Instance connection name} saved from Step 2. Used by Google SQL Cloud proxy later