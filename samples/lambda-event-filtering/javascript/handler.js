/**
 * Lambda Event Filtering Demo
 *
 * Demonstrates AWS Lambda event source filtering with DynamoDB Streams and SQS.
 * - DynamoDB Stream: Only triggers on INSERT events
 * - SQS: Only triggers when message body contains { "data": "A" }
 */

// Process DynamoDB Stream events (filtered to INSERT only)
exports.processDynamoDBStream = async (event) => {
    console.log('DynamoDB Stream Event:', JSON.stringify(event, null, 2));

    for (const record of event.Records) {
        console.log('Event Name:', record.eventName);
        console.log('New Image:', JSON.stringify(record.dynamodb.NewImage, null, 2));
    }

    return {
        statusCode: 200,
        body: JSON.stringify({ message: 'DynamoDB stream processed', recordCount: event.Records.length })
    };
};

// Process SQS events (filtered to messages with data: "A")
exports.processSQS = async (event) => {
    console.log('SQS Event:', JSON.stringify(event, null, 2));

    for (const record of event.Records) {
        const body = JSON.parse(record.body);
        console.log('Message Body:', body);
        console.log('Data value:', body.data);
    }

    return {
        statusCode: 200,
        body: JSON.stringify({ message: 'SQS message processed', recordCount: event.Records.length })
    };
};
