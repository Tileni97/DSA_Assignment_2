Running MySQL on Docker is straightforward. You can use the official MySQL Docker image available on Docker Hub. Here's a step-by-step guide to get you started:

1. **Pull the Official MySQL Image**

   Start by pulling the latest MySQL image:

   ```bash
   docker pull mysql:latest
   ```

2. **Run a MySQL Container**

   The following command starts a new MySQL container with a specified root password:

   ```bash
   docker run --name assignment2 -e MYSQL_ROOT_PASSWORD=your-password -d mysql:latest
   ```


3. **Optionally, Create a Database on First Run**

   If you want to create a database when the image is first initialized, you can use the `MYSQL_DATABASE` environment variable:

   ```bash
   docker run --name assignment2 -e MYSQL_ROOT_PASSWORD=your-password -e MYSQL_DATABASE=assignment2-db -d mysql:latest
   ```

4. **Connect to MySQL**

   ```bash
   docker exec -it assignment-2 mysql -uroot -p
   ```

docker run --name some-mysql -e MYSQL_ROOT_PASSWORD=root -p 3307:3306 -d mysql:latest

#the command above lets you run the mwsql docker img at localhost, much easier

   This command uses `docker exec` to run the `mysql` client inside the "assignment2" container. You will be prompted for the password (in this case, "password").

5. **Data Persistence**

   Docker containers are ephemeral, which means data inside them can be lost once the container stops or is removed. To persist MySQL data, you can use Docker volumes.

   Create a volume:

   ```bash
   docker volume create mysql-data
   ```

   Now, when starting your MySQL container, mount this volume to the MySQL data directory:

   ```bash
   docker run --name some-mysql -v mysql-data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mysql:latest
   ```

   With this setup, even if the container is removed and recreated, the data will persist.

6. **Accessing MySQL from Other Applications or Containers**

   If you want to access your MySQL server from another application or container, you can publish the MySQL port (default is 3306) on your host:

   ```bash
   docker run --name assignment2 -e MYSQL_ROOT_PASSWORD=your-password -p 3306:3306 -d mysql:latest
   ```

   Now, you can connect to MySQL using `localhost` (or your machine's IP) and the default port 3306.

7. **Building the docker images**

docker build -t your-graphql-server-image-name .

#do that in both server and client folders

docker run -d -p 8080:8080 your-graphql-server-image-name
docker run -d -p 8081:8081 your-graphql-client-image-name


8. **Accessing MySQL from Other Applications or Containers**
9. **Accessing MySQL from Other Applications or Containers**
10. **Accessing MySQL from Other Applications or Containers**