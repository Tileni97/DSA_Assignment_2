# Use the official Ballerina Docker image
FROM ballerina/ballerina-ce:latest

# Set the working directory
WORKDIR /usr/src/app

# Copy the client files to the working directory
COPY GraphQLClient.bal .

# Run the client (assuming the service is running at http://localhost:8081)
CMD ballerina run GraphQLClient.bal
