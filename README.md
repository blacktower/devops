# WordPress DevOps
Teaching myself how to create a bootstrap for loading linux packages required for a WordPress LAMP infrastructure on multiple cloud platforms. Targeting Ubunto 16 Xenial on AWS and Debian 9 Stretch on Google.

Initial design is to have a minimal "bootstrap" script that would download and call the main package loading script. The package loader would also set Apache and PHP configurations.

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
