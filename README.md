# Real-time Twitter Sentiment Analysis on Cloudera Data Platform (CDP)

## Introduction

This solution aims to provide real-time monitoring of the current sentiment about any topic on Twitter. Specifically, it answers questions like: "Within the last X minutes, how many positive and negative tweets about topic Y were posted? How does this compare to the average? What is the trend we're seeing currently?"

The solution uses Cloudera Data Platform to build and deploy the solution. The main components used are:

- **Cloudera Data Flow** to build a NiFi flow that retrieves data from the Twitter Filtered stream API.
- **Cloudera Machine Learning** Model API to run sentiment analysis on each tweet. The API uses a Hugging Face deep learning model pre-trained on sentiment analysis.
- **Cloudera Data Hub** template to deploy a Kafka cluster.

The NiFi flow retrieves tweets from the Twitter Filtered stream API, runs some pre-processing, makes a call to the Cloudera Machine Learning Model API for sentiment analysis, post-processes the results, and produces them into a Kafka topic. The results are then stored and accessed from another Data Hub cluster using SQL Streams Builder.

The solution uses SSL for encrypting data in transit between clusters, and NiFi for encrypting sensitive data and credentials.

Overall the solution allows to have a real time monitoring of the sentiment about a specific topic, giving an idea of how people are feeling about that topic, and also the trend and comparison with the average sentiment.


## Data Retrieval

The NiFi flow retrieves data from the Twitter Filtered stream API using the `ConsumeTwitter` processor. This processor references the `#{TwitterBearerToken}` secret, which is used by the Twitter API to identify the API user.

The Filtered stream API is pre-configured with rules to grab tweets from certain topics without retweets and in English language only. An example of a rule for the topic "Tesla" is:

```json
{
    "value": "(tesla OR #tesla OR @tesla OR from:tesla OR to:tesla) -is:retweet lang:en",
    "tag": "tesla"
}
```

This rule will grab tweets that contain the word "Tesla", the hashtag "#tesla", tweets from or to the account "@tesla", and exclude retweets.

The ConsumeTwitter processor also provides options to limit the number of tweets retrieved, and to set a time interval for retrieval. This allows the solution to be configured to retrieve tweets from the last X minutes.

Once the tweets are retrieved, they are passed on to the next steps of the NiFi flow for pre-processing and sentiment analysis.

It's important to note that you need to have an active Twitter developer account, and to create a bearer token to use the Twitter Filtered Stream API. The bearer token is used as a secret and should be kept secured.

## Pre-processing

After the tweets are retrieved, they are passed through a pre-processing step in the NiFi flow. This step uses the `JOLTTransformJSON` processor to transform the tweets into a schema that the Cloudera Machine Learning Model (CML) API can accept.

The `JOLTTransformJSON` processor takes the original schema of the tweets, which is:

```json
{
  "data": {
    "id": "1067094924124872705",
    "edit_history_tweet_ids": [
      "1067094924124872705"
    ],
    "text": "Example text",
    "tag": "tesla"
  }
}
```

and transforms it into the following schema:

```json
{
  "request": {
    "id": "1067094924124872705",
    "text": "Example text",
    "tag": "tesla"
  }
}
```

The CML API requires the text of the tweet to be in the "text" field, and the id in the "id" field, with no other additional information. The `JOLTTransformJSON` processor allows to make this transformation in a easy way, making the process simple and efficient.

It's important to note that you need to have access to the Cloudera Machine Learning API, and that the model should be pre-trained on sentiment analysis.

This pre-processing step ensure that the data is in the correct format, and it's ready to be passed to the next step, the sentiment analysis, without additional issues


## Sentiment Analysis

After the tweets have been pre-processed, they are passed to the sentiment analysis step in the NiFi flow. This step uses the `InvokeHTTP` processor to call the Cloudera Machine Learning Model (CML) API and run sentiment analysis on each tweet.

The `InvokeHTTP` processor makes a POST request to the CML API, passing the pre-processed tweet as the payload of the request. The HTTP URL is parameterized: #{CMLModelEndpoint}?accessKey=#{CMLModelEndpointAccessKey}. This allows the solution to easily change the endpoint and access key of the CML API without modifying the flow.

The CML API returns a response containing the sentiment analysis results for the tweet. This response is in JSON format and it contains success, response, ReplicaID, Size and StatusCode fields.

The post-processing step uses another `JOLTTransformJSON` to simplify the responses from the CML model API. The resulting schema is:

```json
{
    "created_at": "2023-01-11T15:05:45.000Z",
    "id": "1613190434120949761",
    "label": "positive",
    "negative": 0.0042450143955647945,
    "neutral": 0.011172760277986526,
    "positive": 0.984582245349884,
    "text": "I love hackathons!"
}
```

This way, the response is simplified and is ready to be passed to the next step, the results production to a Kafka topic.

It's important to note that you need to have access to the Cloudera Machine Learning API, and that the model should be pre-trained on sentiment analysis, and that the API should be configured to handle the requests from the NiFi flow.

## Kafka Cluster:
The results of the sentiment analysis are produced to a Kafka topic using the PublishKafka2RecordCDP processor. This processor is configured to publish the sentiment analysis results to a specific topic on the Kafka cluster.

The Kafka cluster was deployed as a Cloudera Data Hub using the following Data Hub template: 7.2.16 - Streams Messaging Light Duty. This template provides a quick and easy way to set up a Kafka cluster with minimal configuration.

The PublishKafka2RecordCDP processor relies on the StandardRestrictedSSLContextService NiFi service for encrypting data in transit between the NiFi cluster and the Kubernetes cluster where the Kafka cluster is deployed. This ensures that the data is secure and protected while it's in transit.

## Streaming Analytics

The data is finally accessed from another Data Hub cluster that was deployed from the 7.2.16 - Streaming Analytics Light Duty with Apache Flink template. The results are processed in an application built in SQL Streams Builder from the results that are stored in a virtual table based on the Kafka topic.

The virtual table is created using the SQL Streams Builder, and it's based on the Kafka topic where the results of the sentiment analysis are produced. The virtual table allows to query the data in real-time, and it's updated as new data is produced to the Kafka topic.

The SQL Streams Builder allows to create and configure a data pipeline, where the data is ingested, transformed, and stored. The application built in SQL Streams Builder, allows to process the data in real-time, such as calculating the average sentiment, counting the number of positive and negative tweets, and creating a trend graph.

The results can be accessed through the SQL Streams Builder, which allows to create and configure the data pipeline, or by querying the virtual table directly.

It's important to note that the Data Hub cluster should be configured to handle the requests from the NiFi flow, and should be able to handle the amount of data that is going to be produced and processed. Also, it's important to check that the Data Hub cluster is running, and that the virtual table is created and it's accessible.

### SQL Streams Builder Virtual Table

To create a virtual table using the SQL Streams Builder, follow these steps:

Access the SQL Streams Builder by navigating to the Data Hub cluster in the Cloudera Manager.

Click on the "New Streams" button to create a new data pipeline.

In the "New Streams" window, give a name to the pipeline, and select "Kafka" as the data source.

In the "Data Source" tab, select the Kafka topic "twitter-sentiment" as the source of the data.

In the "Schema" tab, define the schema of the virtual table. This should match the schema of the sentiment analysis results.

In the "Transform" tab, you can add any additional transformation or calculation that you want to perform on the data before it is stored in the virtual table.

In the "Store" tab, select the location where you want to store the virtual table. This could be a Hive table, a Kudu table, or a HBase table.

Click on the "Create" button to create the pipeline and the virtual table.

Once the pipeline is created, you can start it by clicking on the "Start" button.

It's important to note that you need to have access to the SQL Streams Builder, and that the virtual table should be created with the correct schema, to match the results of the sentiment analysis. Also, the virtual table should be accessible and the pipeline should be running to query the data from it.
