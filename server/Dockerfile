# Use the official Ballerina Docker image
FROM balorg/ballerina-ce:main




# Set the working directory
WORKDIR /usr/src/app

# Copy the service files to the working directory
COPY YourService.bal .

# Expose the port your service is running on
EXPOSE 8081

CMD ballerina run YourService.bal
