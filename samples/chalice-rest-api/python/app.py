"""
Chalice REST API application.

A simple TODO API demonstrating Chalice framework with LocalStack.
"""

from chalice import Chalice, NotFoundError, Response

app = Chalice(app_name="todo-app")
app.debug = True

# In-memory TODO storage
TODO_ITEMS = {
    "1": {"item": "Run LocalStack in detached mode"},
    "2": {"item": "Run your Chalice REST API with LocalStack"},
}


@app.route("/")
def index():
    """Root endpoint returning API info."""
    return {"localstack": "chalice integration"}


@app.route("/health")
def health_check():
    """Health check endpoint."""
    return Response(status_code=200, body="ok\n", headers={"Content-Type": "text/plain"})


@app.route("/todo")
def todos():
    """List all TODO items with optional pagination."""
    items = [v for k, v in TODO_ITEMS.items()]

    params = app.current_request.query_params
    if params:
        offset = int(params.get("offset", 0))
        size = int(params.get("size", len(TODO_ITEMS)))
        return items[offset:size]

    return items


@app.route("/todo/{todo_id}")
def get_todo(todo_id):
    """Get a specific TODO item."""
    if todo_id in TODO_ITEMS:
        return TODO_ITEMS[todo_id]
    raise NotFoundError


@app.route("/todo/{todo_id}", methods=["DELETE"])
def delete_todo(todo_id):
    """Delete a TODO item."""
    item = TODO_ITEMS[todo_id]
    del TODO_ITEMS[todo_id]
    return item


@app.route("/todo/{todo_id}", methods=["POST", "PUT"])
def update_todo(todo_id):
    """Update a TODO item."""
    if app.current_request.method == "POST":
        TODO_ITEMS[todo_id].update(app.current_request.json_body)
    else:
        TODO_ITEMS[todo_id] = app.current_request.json_body
    return TODO_ITEMS[todo_id]


@app.route("/introspect")
def introspect():
    """Return the current request details."""
    return app.current_request.to_dict()


@app.route("/todo", methods=["POST"])
def add_todo():
    """Add a new TODO item."""
    todo = app.current_request.json_body
    new_id = str(len(TODO_ITEMS) + 1)
    TODO_ITEMS[new_id] = todo
    return todo
