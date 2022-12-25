# 1. Background

## Data Maturity Model
Data Collection -> Data Wrangling -> Data Integration -> BI and Analytics -> Artificial Intelligence

### Data Collection
The extraction of data from different source systems. Big data (variety, velocity and volume)

### Data Wrangling
Improving the data quality. Convert the data from its operational source format into a data warehouse format. 

### Data Integration
Writing the transformed data from the staging area to a target database for analytics. Two ways: rewriting the data completely and replace the old data, or only apply the changes to the warehouse. 

### ETL & ELT
Above are essentially ETL (Extract, Transform and Load) concepts. ETL is the traditional approach that does transformation outside of the database because storage and compute were a lot more expensive back in the days. The problem with ETL is, the data changes over time, if there is a schema change, the model is broken, and it was hard to scale. 

With cost of storage and compute reducing, there's no harm loading raw data directly into the destination. Data warehouses such as Snowflake, Redshift and BigQuery are extremely scalable and performant, so it makes sense to do transformations inside the database (ELT), so issues with upstream schemas and downstream data models can be easily handled. Today, there are tools such as Fivetran and Stitch etc that allow us to load data into destination with just a few clicks. 

## Data Warehousing (DW, or DWH)
A database that serve as the technology for data analytics and reporting. It allow us to do high performance analytics and create dimensions, facts and handle demoralization. They work well with columnar storage formats and complex data types, but generally cannot handle unstructured data such as images and videos. Typically, you interact with the data warehouse by executing sql against it. 

It is important to keep the data int he DWH well structured and clean, so it won't take you a long time a answer simple questions. 

As cloud computing becomes available, many organizations has shifted from on-prem to the cloud based warehouses. 

## External tables and Cloud Data Warehouses
External tables means for structured data, we store large files outside of the data warehouse, such as Amazon S3 or blob storage, so we can decouple the compute component from the storage component, and scale the compute and the storage independently from the data warehousing instances. There will not be any practical difference when implementing this, because these external tables will be stored with a serverless service. 

## Data Lake
A repo where you can store unstructured data, semi-structured data, and structured data, like a scalable file system. On premise, this is called the HDFS (Hadoop distributed file system), but for the cloud, there is Amazon S3, etc. The point ot data lake is to save files so there is no computing integrated, so you can scale you compute instances independently from storage. If you use DataBricks or Snowflake, they will store your data in the data lake by default, and they will provide you with analytical clusters that you can set up the way you want, for compute. 

## Data Lakehouse
The Lake house concept emerged due to the limitation of data lakes. It combines the best features of data lakes and data warehouses. The lake house have very similar data structure and data management features as data warehouse, but it sits on top of a low cost cloud storage. Also, you get ACID transactional support so you can ensure consistency. The schema of the data is stored in the Lakehouse meta store. You can evolve the schema of your tables without having ot make a copy of the dataset. You can control and authorize access to your data. 

## The Modern Data Stack
SMP (Symmetric multi processing) system contains multiple processors that share the same memory and operate under a single OS. While in a MPP (Massive parallel programming) system, each processor has its own dedicated resources and shares nothing. 

The shift from SMP to MPP was a very critical step towards the modern data stack. Another important step was the decoupling of storage and compute. You can shut down the compute nodes when you don't need them and your data will be safe inside a low cost storage system such as Amazon S3 or Azure blob storage. So if you have a very compute intensive workload, you can just add more compute to your cluster without having to scale the storage.

Another step that contributed to the modern data stack was the introduction of column-oriented databases. ETL -> ELT. 

## Slowly Changing Dimension (SCD)

















