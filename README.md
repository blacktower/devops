# WordPress DevOps
Teaching myself how to build a bootstrap for building WordPress infrastructure on multiple cloud platforms. Targeting Ubunto Xenial on AWS and Debian Jessie on Google

## Google Cloud Compute and SQL
Using the admin console:
1. Enable Goolge Cloud SQL API (Go to API Manager -> Enable API -> Google Cloud SQL API)
2. Create the Cloud SQL instance
   - Save the Instance connection name for the compute engine
   - Add the databae name 'wordpress'
2. Create the Compute Engine
   - Set Identity and API Access -> Access Scope = 'Allow full access to all Cloud APIs' 
   - Enable HTTP and HTTPS access under Firewall
   - Copy contents of bootstrap.sh into Startup Script
   - Fill in the OS and PROVIDER variables
   - Under Managment, add the following Metadata fields:
     - key = sqlproxy 
     - value=<Cloud SQL Instance connection name> saved from Step 2, (used by Google SQL Cloud proxy later)

## Amazon EC2 and RDS
Using the admin console:
1. do some stuff......
