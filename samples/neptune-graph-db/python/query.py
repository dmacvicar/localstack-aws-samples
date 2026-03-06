"""
Neptune Graph Database query handler.

This module provides functions to create, query, and manage Neptune Graph DB clusters.
"""

import os
import time
import boto3

# Import gremlin_python modules for graph queries
try:
    from gremlin_python.driver import client as gremlin_client
    from gremlin_python.structure.graph import Graph
    from gremlin_python.driver.driver_remote_connection import DriverRemoteConnection
    GREMLIN_AVAILABLE = True
except ImportError:
    GREMLIN_AVAILABLE = False

LOCALSTACK_ENDPOINT = os.environ.get("LOCALSTACK_ENDPOINT", "http://localhost.localstack.cloud:4566")


def poll_condition(condition, timeout: float = None, interval: float = 0.5) -> bool:
    """Poll a condition until it returns True or timeout."""
    remaining = 0
    if timeout is not None:
        remaining = timeout

    while not condition():
        if timeout is not None:
            remaining -= interval
            if remaining <= 0:
                return False
        time.sleep(interval)

    return True


def connect_neptune(region: str = "us-east-1"):
    """Create a Neptune client."""
    return boto3.client(
        "neptune",
        endpoint_url=LOCALSTACK_ENDPOINT,
        region_name=region,
        aws_access_key_id=os.environ.get("AWS_ACCESS_KEY_ID", "test"),
        aws_secret_access_key=os.environ.get("AWS_SECRET_ACCESS_KEY", "test"),
    )


def create_graph_db(cluster_id: str):
    """Create a Neptune Graph DB cluster and wait for it to be available."""
    print(f'Creating Neptune Graph DB cluster "{cluster_id}" - this may take a few moments ...')
    client = connect_neptune()
    cluster = client.create_db_cluster(DBClusterIdentifier=cluster_id, Engine="neptune")["DBCluster"]

    def is_cluster_available():
        clusters = client.describe_db_clusters()
        for c in clusters["DBClusters"]:
            if c["DBClusterIdentifier"] == cluster_id:
                return c["Status"] == "available"
        return False

    cluster_available = poll_condition(is_cluster_available, timeout=30, interval=1)
    if not cluster_available:
        raise Exception("The server took too much time to start")

    # Get updated cluster info with port
    clusters = client.describe_db_clusters()
    for c in clusters["DBClusters"]:
        if c["DBClusterIdentifier"] == cluster_id:
            return c

    return cluster


def delete_db(cluster_id: str):
    """Delete a Neptune Graph DB cluster."""
    print(f'Deleting Neptune Graph DB cluster "{cluster_id}"')
    client = connect_neptune()
    try:
        client.delete_db_cluster(DBClusterIdentifier=cluster_id)
    except Exception as e:
        print(f"Warning: Could not delete cluster: {e}")


def run_gremlin_queries(cluster):
    """Run Gremlin queries against the Neptune cluster."""
    if not GREMLIN_AVAILABLE:
        print("gremlin_python not available, skipping Gremlin queries")
        return

    cluster_url = f"ws://localhost:{cluster['Port']}/gremlin"

    # Test Client API
    print(f"Connecting to Neptune Graph DB cluster URL: {cluster_url}")
    graph_client = gremlin_client.Client(cluster_url, "g")

    values = "[1,2,3,4]"
    print(f"Submitting values: {values}")
    result_set = graph_client.submit(values)
    future_results = result_set.all()
    results = future_results.result()
    print(f"Received values from cluster: {results}")
    assert results == [1, 2, 3, 4]

    graph_client.close()

    # Test DriverRemoteConnection API
    graph = Graph()
    conn = DriverRemoteConnection(cluster_url, "g")
    g = graph.traversal().withRemote(conn)
    vertices_before = g.V().toList()
    print(f"Existing vertices in the graph: {vertices_before}")
    print('Adding new vertices "v1" and "v2" to the graph')
    g.addV().property("id", "v1").property("name", "Vertex 1").next()
    g.addV().property("id", "v2").property("name", "Vertex 2").next()
    vertices_after = g.V().toList()
    print(f"New list of vertices in the graph: {vertices_after}")
    result = set(vertices_after) - set(vertices_before)
    assert len(result) == 2
    conn.close()


def main():
    """Main entry point for running Neptune queries."""
    cluster_id = "test-cluster"
    instance = None
    try:
        instance = create_graph_db(cluster_id)
        run_gremlin_queries(instance)
    finally:
        if instance:
            delete_db(cluster_id)
    print("Done.")


if __name__ == "__main__":
    main()
