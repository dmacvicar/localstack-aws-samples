# Neptune Graph Database

> **Note**: This sample requires LocalStack to download Java/TinkerGraph on first run, which may take several minutes. The cluster will show "error" status until the download completes.

This sample demonstrates using Amazon Neptune Graph Database locally with LocalStack.

## Overview

Amazon Neptune is a managed graph database service that supports Property Graph and RDF data models. This sample shows how to:

1. Create a Neptune DB cluster
2. Connect to the cluster using Gremlin queries
3. Add and query vertices in the graph

## Architecture

```
Neptune Cluster
    └── Gremlin Endpoint (WebSocket)
         └── Graph queries (vertices, edges, traversals)
```

## Services Used

- **Amazon Neptune**: Managed graph database with Gremlin support

## Prerequisites

- LocalStack Pro (Neptune is a Pro feature)
- Python 3.10+
- gremlinpython (optional, for running Gremlin queries)

## IaC Methods

| Method | Status | Notes |
|--------|--------|-------|
| scripts | Supported | AWS CLI deployment |
| terraform | Limited | Neptune may have limited Terraform support |
| cloudformation | Limited | Neptune may have limited CloudFormation support |
| cdk | Limited | Neptune may have limited CDK support |

## Deployment

### Using Scripts (AWS CLI)

```bash
cd samples/neptune-graph-db/python

# Deploy
./scripts/deploy.sh

# Teardown
./scripts/teardown.sh
```

## Testing

```bash
# Run all tests
uv run pytest samples/neptune-graph-db/python/ -v

# Run specific IaC method
uv run pytest samples/neptune-graph-db/python/ -v -k scripts
```

## Running Gremlin Queries

After deployment, you can run Gremlin queries against the cluster:

```bash
# Install gremlin dependencies
pip install gremlinpython

# Run the query script
python query.py
```

## Resources Created

- Neptune DB Cluster (`neptune-test-cluster`)

## Environment Variables

After deployment, the following variables are written to `scripts/.env`:

- `CLUSTER_ID`: Neptune cluster identifier
- `CLUSTER_ARN`: Neptune cluster ARN
- `CLUSTER_ENDPOINT`: Cluster endpoint (if available)
- `CLUSTER_PORT`: Cluster port for Gremlin connections

## Troubleshooting

### Cluster not available

Neptune clusters may take a few seconds to become available after creation. The deploy script waits up to 30 seconds for the cluster to be ready.

### Gremlin connection issues

Ensure the cluster is in "available" status before attempting Gremlin connections:

```bash
awslocal neptune describe-db-clusters --db-cluster-identifier neptune-test-cluster
```

## License

Apache 2.0
