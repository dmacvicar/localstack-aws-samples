/**
 * WebSocket handler for API Gateway WebSocket routes.
 * Handles $connect, $disconnect, $default, and custom action routes.
 */
module.exports.handler = function(event, context, callback) {
  console.log('WebSocket event:', JSON.stringify(event, null, 2));

  const routeKey = event.requestContext?.routeKey;
  const connectionId = event.requestContext?.connectionId;

  // Handle different route types
  if (routeKey === '$connect') {
    console.log(`Client connected: ${connectionId}`);
    if (callback) {
      callback(null, { statusCode: 200, body: 'Connected' });
    } else {
      context.succeed({ statusCode: 200, body: 'Connected' });
    }
  } else if (routeKey === '$disconnect') {
    console.log(`Client disconnected: ${connectionId}`);
    if (callback) {
      callback(null, { statusCode: 200, body: 'Disconnected' });
    } else {
      context.succeed({ statusCode: 200, body: 'Disconnected' });
    }
  } else {
    // Echo back the event for $default and custom actions
    console.log(`Message received on route: ${routeKey}`);
    if (callback) {
      callback(null, event);
    } else {
      context.succeed(event);
    }
  }
};
