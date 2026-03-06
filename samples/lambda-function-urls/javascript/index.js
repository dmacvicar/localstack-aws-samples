exports.handler = async (event) => {
    let body;

    // Handle both direct invocation and HTTP requests
    if (typeof event.body === 'string') {
        body = JSON.parse(event.body);
    } else if (event.body) {
        body = event.body;
    } else {
        body = event;
    }

    const num1 = parseFloat(body.num1) || 0;
    const num2 = parseFloat(body.num2) || 0;
    const product = num1 * num2;

    const response = {
        statusCode: 200,
        body: JSON.stringify({
            message: `The product of ${num1} and ${num2} is ${product}`,
            result: product
        }),
    };
    return response;
};
