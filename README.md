# devops
stuff to make my life easier

## Google Cloud
1. Go to API Manager -> Enable API -> Google Cloud SQL API and enable
2. Create the Cloud SQL instance (you'll need the Instance connection name for the compute engine)
  - Add the databae name = wordpress
2. Create the Compute Engine
  - Copy contents of startup into Startup Script
  - Add a metadata field:
    - key = sqlproxy 
    - value={Cloud SQL Instance connection name} found in your Google Console. Used by Google SQL Cloud proxy later