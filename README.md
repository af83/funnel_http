# Funnel

[![Build Status](https://travis-ci.org/AF83/funnel_http.png?branch=master)](https://travis-ci.org/AF83/funnel_http)

Funnel is for building Streaming APIs build upon ElasticSearch’s
[percolation](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-percolate.html).

Funnel supports ElasticSearch >= 1.1.

Funnel allow to register users / devices, associates some queries to user, and
exposes a streaming endpoint for each user.

The common usecase is to store a query from a user and notify this user when a
new document matching this query is available.

## Doing things

Elixir must be installed.

### Running things

Starting the HTTP API:

``` shell
mix do deps.get, deps.compile, server
```

### Testing things

``` shell
mix test
```

### Register

A user, or a device, can register to funnel by using the `/register` endpoint.
This will return a token. This token must be used in all communications with the
funnel's API.

``` shell
curl -H "Content-Type: application/json" -H "Accept: application/json" -XPOST http://localhost:4000/register
```
``` json
{"token":"7d0ac81fbdd646dd9e883e3b007ce58d"}
```

The token can be passed as a parameter, or by using the Authorization header.

For the sake of readability, we assume those headers for all subsequent
examples:

``` shell
-H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: 7d0ac81fbdd646dd9e883e3b007ce58d"
```

### Index

Ok, now, let's create an index:

``` shell
curl -XPOST "http://localhost:4000/index" -d '{"settings" : {"number_of_shards" : 1},"mappings" : {"type1" : {"_source" : {"enabled" : false},"properties" :{"field1":{"type":"string","index":"not_analyzed"}}}}}'
```
``` json
{"index_id":"bfa3e5b02e554b458165815968ed490b","body":{"ok":true,"acknowledged":true}}
```

An index can be destroy:

``` shell
curl -XDELETE "http://localhost:4000/index/bfa3e5b02e554b458165815968ed490b"
```
``` json
{"found":true,"_index":"ed78ca7c475449a59fa70ecc90ea0634_dev","_type":".percolator","_id":"0f415001bc774a129921c4d929e3cd7c-14e8a26c56d04db2a1829d289ca7e91c","_version":3}
```

### Query

#### Adding query

Adding queries is done by using the `/query` endpoint. The payload must
comply with the funnel's query serialization. These entries can accept a single
query, or a list of queries.

A query is defined by a user's token, a set of metadata, and the elasticsearch
query. `metadata` and `query` are mandatory.

``` shell
curl -XPOST "http://localhost:4000/index/bfa3e5b02e554b458165815968ed490b/queries" -d '{"query":{query" : {"term" : {"field1" : "value1"}}}, "metadata":{"name":"Awesome Query"}}'
```
``` json
{"query_id":"c4d92d29273a4bec9618c65c3c33e9db","index_id":"ed78ca7c475449a59fa70ecc90ea0634","metadata":{"name":"Awesome Query"}}
```

#### Updating a query

``` shell
curl -XPOST "http://localhost:4000/index/bfa3e5b02e554b458165815968ed490b/queries/c4d92d29273a4bec9618c65c3c33e9db" -d '{"query":{"query" : {"term" : {"field1" : "value1"}}},"metadata":{"name":"Awesome Query"}}'
```

``` json
{"query_id":"c4d92d29273a4bec9618c65c3c33e9db","index_id":"ed78ca7c475449a59fa70ecc90ea0634","metadata":{"name":"Awesome Query"}}
```

#### Deleting a query

``` shell
curl -XDELETE "http://localhost:4000/index/bfa3e5b02e554b458165815968ed490b/queries/c4d92d29273a4bec9618c65c3c33e9db"
```

``` json
{"acknowledged":true}
```

#### Searching queries

Queries can be retrieved for a given `index_id` with the following:

``` shell
curl -XGET "http://localhost:4000/index/bfa3e5b02e554b458165815968ed490b/queries"
```
``` json
[{"query_id":"c4d92d29273a4bec9618c65c3c33e9db","index_id":"ed78ca7c475449a59fa70ecc90ea0634","score":1.0}]
```

Queries can be retrieved for a given `token` with the following:

``` shell
curl -XGET "http://localhost:4000/queries"
```
``` json
[{"query_id":"c4d92d29273a4bec9618c65c3c33e9db","index_id":"ed78ca7c475449a59fa70ecc90ea0634","score":1.0}]
```

### Submiting documents

Adding messages is done by using the `/feeding` endpoint. The payload must
comply with the funnel's message serialization.


``` shell
curl -XPOST "http://localhost:4000/index/bfa3e5b02e554b458165815968ed490b/feeding" -d '{"doc":{"field1" : "value1"}}'
```

### Streaming

Listening to a stream is done by using the `/river` endpoint.
Message from this endpoint has the same serialization as the message sent to
`/feeding`, with one addition: an entry query containing the query's name.
River will send messages from all queries associated to the user/token.

Rivers uses Server-sent events to maintain an open connection.

``` shell
curl "http://localhost:4000/river?token=7d0ac81fbdd646dd9e883e3b007ce58d"
data: {"query_ids":["c4d92d29273a4bec9618c65c3c33e9db"],"body":"{\"doc\":{\"field1\":\"value1\"}}"}
```

River provides a local cache. If a `last_id` params is given, any item more
recent will be returned.

### Monitoring

Funnel can be monitored on `/status`. Each resquest on this endpoint does a
request on ElasticSearch root.
