# 3. About dbt Cloud
## dbt Cloud features
Develop, test, schedule, document, and investigate data models, all in one browser-based UI:
- dbt Cloud IDE
- Manage prod/dev envs, dev env for CI
- Schedule/run dbt jobs, view run history
- Job notifications
- Host docs
- GitHub/GitLab/AzureDevOps support

## dbt Cloud Architecture
The dbt Cloud spp has two components: 
- The static components are always running, to serve highly available dbt Cloud functions, like the dbt Cloud web app. 
- The dynamic components are created ad-hoc, to handle tasks such as background jobs, or requests to use the IDE.

dbt Cloud is available in most regions around the world, in both single tenant (AWS and Azure), and multi-tenant configurations.

dbt Cloud uses PostgreSQL for its backend, S3-compatible Object Storage systems for logs/artifacts, and a Kubernetes storage solution for creating dynamic, persistent volumes.

All data at rest on dbt Cloud servers is protected using AES-256 encryption. dbt Cloud encrypts data in transit using the TLS 1.2 protocol.

Some data warehouse providers offer advanced security features, that can be leveraged in dbt Cloud. PrivateLink allows supported data platforms on AWS to communicate with dbt Cloud, without the traffic traversing the public internet. Snowflake and BigQuery offer Oauth integration, which adds a layer of security for the data platforms. 

## Tenancy
dbt Cloud is available in both single (virtual private) and multi-tenant configurations. 

The Multi Tenant (SaaS) deployment environment refers to the SaaS dbt Cloud application, hosted by dbt Labs. Most commonly used. Managed service. Hosted on AWS. 

Single tenant dbt Cloud instances provide dedicated infrastructure, in a virtual private cloud (VPC) environment. Is a Infrastructure as Code (IaC) deployment built with Terraform. Lives in a dedicated AWS or Azure account, and can be customized with certain configurations, such as firewall rules, to limit inbound traffic, or hosting in a specific regions.

## Regions & IP addresses
dbt Cloud is hosted in multiple regions, and will always connect to your data platform, or git provider, from a few IP addresses. 

Be sure to allow traffic from these IPs in your firewall, and include them in any database grants.

dbt Cloud Enterprise plans can choose to have their account hosted certain regions. Organizations must choose a single region, per dbt Cloud account. 

If you need to run dbt Cloud in multiple regions, then use multiple dbt Cloud accounts.

## About dbt Cloud IDE
A single interface for building, testing, running, and version-controlling dbt projects from your browser. 

The IDE leverages the open-source dbt-rpc plugin, to recompile only the changes made in your project.

## Supported browsers
skipped. 
