/**
 * ELB Lambda handlers.
 *
 * These handlers respond to ALB requests with simple messages.
 * Response format follows ALB Lambda integration requirements.
 */

// Handler for /hello1 path
module.exports.hello1 = async (event) => {
    console.log('hello1 invoked:', JSON.stringify(event));
    return {
        isBase64Encoded: false,
        statusCode: 200,
        statusDescription: '200 OK',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ message: 'Hello 1', path: '/hello1' })
    };
};

// Handler for /hello2 path
module.exports.hello2 = async (event) => {
    console.log('hello2 invoked:', JSON.stringify(event));
    return {
        isBase64Encoded: false,
        statusCode: 200,
        statusDescription: '200 OK',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ message: 'Hello 2', path: '/hello2' })
    };
};

// Default handler
module.exports.handler = async (event) => {
    console.log('default handler invoked:', JSON.stringify(event));
    return {
        isBase64Encoded: false,
        statusCode: 200,
        statusDescription: '200 OK',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ message: 'Hello from ELB Lambda' })
    };
};
