import ballerina/graphql;
import ballerina/sql;
import ballerinax/mysql;
import ballerina/log;
import ballerina/random; // For generating random salts

# Description.
#
# + id - field description  
# + firstName - field description  
# + lastName - field description  
# + jobTitle - field description  
# + position - field description  
# + role - field description  
# + department - field description
public type User record {
    int id;
    string firstName;
    string lastName;
    string jobTitle?;
    string position?;
    UserRole role;
    Department department?;
};

# Description.
#
# + id - field description  
# + name - field description  
# + hodId - field description  
# + hod - field description  
# + objectives - field description  
# + users - field description
public type Department record {
    int id;
    string name;
    int hodId?;
    User hod?;
    DepartmentObjective[] objectives?;
    User[] users?;
};

# Description.
#
# + id - field description  
# + name - field description  
# + weight - field description  
# + department - field description  
# + relatedKPIs - field description
public type DepartmentObjective record {
    int id;
    string name;
    float weight;
    Department department?;
    KPI[] relatedKPIs?;
};

# Description.
#
# + id - field description  
# + user - field description  
# + name - field description  
# + metric - field description  
# + unit - field description  
# + score - field description  
# + relatedObjectives - field description
public type KPI record {
    int id;
    User user;
    string name;
    string metric?;
    string unit?;
    float score?;
    DepartmentObjective[] relatedObjectives?;
};

public enum UserRole {
    HoD,
    Supervisor,
    Employee
};

// For demonstration, some mock data
User mockUser = {
    id: 1,
    firstName: "John",
    lastName: "Doe",
    role: HoD
};

Department mockDepartment = {
    id: 1,
    name: "Computer Science",
    hod: mockUser
};

DepartmentObjective mockObjective = {
    id: 1,
    name: "Improve Research",
    weight: 75.0,
    department: mockDepartment
};

KPI mockKPI = {
    id: 1,
    user: mockUser,
    name: "Research Papers Published",
    metric: "Number",
    unit: "Papers",
    score: 4.5,
    relatedObjectives: [mockObjective]
};

// User Authentication related types and functions

# Description.
#
# + id - field description  
# + username - field description  
# + password - field description
public type UserAuth record {
    int id;
    string username;
    string password;
};

mysql:Client userDB = check new ("localhost", "root", "@Tessa97", "pms", 3306);

@graphql:ServiceConfig {
    graphiql: {
        enabled: true,
        path: "/testingGraphiQL"
    }
}

service /graphql on new graphql:Listener(2023) { // GraphQL service

    resource function get user(int id) returns User|error { // Fetch a user by ID
        sql:ParameterizedQuery query = `SELECT * FROM Users WHERE id = ${id}`;
        stream<User, sql:Error?> resultStream = userDB->query(query, User);

        record {|User value;|}? result = check resultStream.next();

        // Close the stream
        var closeResult = resultStream.close();

        if (closeResult is error) {
            return closeResult;
        }

        if (result is record {|User value;|}) {
            return result.value;
        } else {
            return error("User not found");
        }
    }

    resource function get department(int id) returns Department|error { // Fetch a department by ID
        sql:ParameterizedQuery depQuery = `SELECT * FROM Departments WHERE id = ${id}`;
        stream<Department, sql:Error?> depStream = userDB->query(depQuery);

        record {|Department value;|}? depResult = check depStream.next();

        if (depResult is record {|Department value;|}) {
            Department dept = depResult.value;

            if (dept.hodId is int) { // Fetch the HoD if the department has one
                sql:ParameterizedQuery hodQuery = `SELECT * FROM Users WHERE id = ${dept.hodId}`;
                stream<User, sql:Error?> hodStream = userDB->query(hodQuery, User);
                record {|User value;|}? hodResult = check hodStream.next();
                if (hodResult is record {|User value;|}) {
                    dept.hod = hodResult.value;
                }
            }

            return dept;
        } else {
            return error("Department not found");
        }
    }
    resource function get departmentObjective(int id) returns DepartmentObjective|error { // Fetch a department objective by ID
        sql:ParameterizedQuery objQuery = `SELECT * FROM DepartmentObjectives WHERE id = ${id}`;
        stream<DepartmentObjective, sql:Error?> objStream = userDB->query(objQuery);

        record {|DepartmentObjective value;|}? objResult = check objStream.next();

        if (objResult is record {|DepartmentObjective value;|}) { // Fetch the department if the objective has one
            DepartmentObjective obj = objResult.value;

            // Fetch related KPIs for this objective
            sql:ParameterizedQuery kpiQuery = `
                SELECT KPIs.* 
                FROM KPIs 
                JOIN ObjectiveKPIRelation ON KPIs.id = ObjectiveKPIRelation.kpiId
                WHERE ObjectiveKPIRelation.objectiveId = ${id}`;
            stream<KPI, sql:Error?> kpiStream = userDB->query(kpiQuery);
            KPI[] kpis = [];
            error? kpiErr = kpiStream.forEach(function(KPI kpi) {
                kpis.push(kpi);
            });
            if (kpiErr is error) {
                return kpiErr;
            }
            obj.relatedKPIs = kpis;

            return obj;
        } else {
            return error("DepartmentObjective not found");
        }
    }

    resource function get kpi(int id) returns KPI|error { // Fetch a KPI by ID
        sql:ParameterizedQuery kpiQuery = `SELECT * FROM KPIs WHERE id = ${id}`;
        stream<KPI, sql:Error?> kpiStream = userDB->query(kpiQuery);

        record {|KPI value;|}? kpiResult = check kpiStream.next();

        if (kpiResult is record {|KPI value;|}) {
            KPI kpi = kpiResult.value;

            // Fetch related objectives for this KPI
            sql:ParameterizedQuery objQuery = `
                SELECT DepartmentObjectives.* 
                FROM DepartmentObjectives 
                JOIN ObjectiveKPIRelation ON DepartmentObjectives.id = ObjectiveKPIRelation.objectiveId
                WHERE ObjectiveKPIRelation.kpiId = ${id}`;
            stream<DepartmentObjective, sql:Error?> objStream = userDB->query(objQuery);

            DepartmentObjective[] objs = [];
            error? objStreamErr = objStream.forEach(function(DepartmentObjective obj) {
                objs.push(obj);
            });

            if (objStreamErr is error) {
                return objStreamErr;
            }

            kpi.relatedObjectives = objs;

            return kpi;
        } else {
            return error("KPI not found");
        }
    }

    resource function get users() returns User[]|error { //users are fetched
        sql:ParameterizedQuery userQuery = `SELECT * FROM Users`;
        stream<User, sql:Error?> userStream = userDB->query(userQuery);
        User[] users = [];

        // Iterate over the stream to populate the users array
        error? e = userStream.forEach(function(User usr) {
            users.push(usr);
        });

        if (e is error) {
            return e;
        }
        return users;
    }

    resource function get departments() returns Department[]|error { //fetch all departments
        sql:ParameterizedQuery depQuery = `SELECT * FROM Departments`;
        stream<Department, sql:Error?> depStream = userDB->query(depQuery);

        Department[] departments = [];
        // Iterate over the stream to populate the departments array
        error? err = depStream.forEach(function(Department dept) {
            departments.push(dept);
        });

        if (err is error) {
            return err;
        }
        return departments;
    }

    //fetch all department objectives
    resource function get departmentObjectives() returns DepartmentObjective[]|error {
        sql:ParameterizedQuery objQuery = `SELECT * FROM DepartmentObjectives`;
        stream<DepartmentObjective, sql:Error?> objStream = userDB->query(objQuery);

        DepartmentObjective[] objectives = [];

        // Iterate over the stream to populate the objectives array
        error? err = objStream.forEach(function(DepartmentObjective obj) {
            objectives.push(obj);
        });

        if (err is error) {
            return err;
        }
        return objectives;
    }

    //fetch all KPIS
    resource function get kpis() returns KPI[]|error {
        sql:ParameterizedQuery kpiQuery = `SELECT * FROM KPIs`;
        stream<KPI, sql:Error?> kpiStream = userDB->query(kpiQuery);

        KPI[] kpis = [];

        // Iterate over the stream to populate the kpis array
        error? err = kpiStream.forEach(function(KPI kpi) {
            kpis.push(kpi);
        });

        if (err is error) {
            return err;
        }
        return kpis;
    }

    //MUTATIONS

    resource function get createUser(string firstName, string lastName, string jobTitle, string position, UserRole role, int departmentId) returns User|error {

        sql:ParameterizedQuery query = `INSERT INTO Users(firstName, lastName, jobTitle, position, role, departmentId) VALUES(${firstName}, ${lastName}, ${jobTitle}, ${position}, ${role}, ${departmentId})`;

        var response = userDB->execute(query);

        if (response is sql:ExecutionResult) {
            int userId;
            if (response.lastInsertId is int) {
                userId = <int>response.lastInsertId;
            } else {
                return error("Expected lastInsertId to be of type int");
            }

            User newUser = {
                id: userId,
                firstName: firstName,
                lastName: lastName,
                jobTitle: jobTitle,
                position: position,
                role: role,
                department: {id: departmentId, name: ""} // Addressing the missing field, however you might need to fetch the actual department name.
            };
            return newUser;
        } else {
            return response;
        }
    }

    // update user mutation
    resource function get updateUser(int id, string firstName, string lastName, string jobTitle, string position, UserRole role, int departmentId) returns User|error {

        sql:ParameterizedQuery query = `UPDATE Users SET firstName=${firstName}, lastName=${lastName}, jobTitle=${jobTitle}, position=${position}, role=${role}, departmentId=${departmentId} WHERE id=${id}`;

        var response = userDB->execute(query);

        if (response is sql:ExecutionResult) {
            User updatedUser = {
                id: id,
                firstName: firstName,
                lastName: lastName,
                jobTitle: jobTitle,
                position: position,
                role: role,
                department: {id: departmentId, name: ""} // Addressing the missing field, however you might need to fetch the actual department name.
            };
            return updatedUser;
        } else {
            return error("Failed to update user");
        }
    }
    resource function get deleteUser(int id) returns boolean|error {

        sql:ParameterizedQuery query = `DELETE FROM Users WHERE id=${id}`;

        var response = userDB->execute(query);

        if (response is sql:ExecutionResult) {
            return true;
        } else {
            return error("Failed to delete user");
        }
    }

    resource function get createDepartment(string name) returns Department|error {

        sql:ParameterizedQuery query = `INSERT INTO Departments(name) VALUES(${name})`;

        var response = userDB->execute(query);

        if (response is sql:ExecutionResult) {
            int departmentId;
            if (response.lastInsertId is int) {
                departmentId = <int>response.lastInsertId;
            } else {
                return error("Expected lastInsertId to be of type int");
            }

            Department newDepartment = {
                id: departmentId,
                name: name
            };
            return newDepartment;
        } else {
            return error("Failed to create department");
        }
    }

    resource function get updateDepartment(int id, string name) returns Department|error {

        sql:ParameterizedQuery query = `UPDATE Departments SET name=${name} WHERE id=${id}`;

        var response = userDB->execute(query);

        if (response is sql:ExecutionResult) {
            Department updatedDepartment = {
                id: id,
                name: name
            };
            return updatedDepartment;
        } else {
            return error("Failed to update department");
        }
    }

    resource function get deleteDepartment(int id) returns boolean|error {

        sql:ParameterizedQuery query = `DELETE FROM Departments WHERE id=${id}`;

        var response = userDB->execute(query);

        if (response is sql:ExecutionResult) {
            return true;
        } else {
            return error("Failed to delete department");
        }
    }

    resource function get createDepartmentObjective(string name, float weight, int departmentId) returns DepartmentObjective|error {

        sql:ParameterizedQuery query = `INSERT INTO DepartmentObjectives(name, weight, departmentId) VALUES(${name}, ${weight}, ${departmentId})`;

        var response = userDB->execute(query);

        if (response is sql:ExecutionResult) {
            int objectiveId;
            if (response.lastInsertId is int) {
                objectiveId = <int>response.lastInsertId;
            } else {
                return error("Expected lastInsertId to be of type int");
            }

            DepartmentObjective newObjective = {
                id: objectiveId,
                name: name,
                weight: weight,
                department: {id: departmentId, name: ""} // I'm assuming the department's name is not known at this point, so using an empty string. You may need to fetch the actual name or adjust this.
            };
            return newObjective;
        } else {
            return error("Failed to create department objective");
        }
    }

    resource function get updateDepartmentObjective(int id, string name, float weight) returns DepartmentObjective|error {

        sql:ParameterizedQuery query = `UPDATE DepartmentObjectives SET name=${name}, weight=${weight} WHERE id=${id}`;

        var response = userDB->execute(query);

        if (response is sql:ExecutionResult) {
            return {id: id, name: name, weight: weight};
        } else {
            return error("Failed to update department objective");
        }
    }

    resource function get deleteDepartmentObjective(int id) returns boolean|error {

        sql:ParameterizedQuery query = `DELETE FROM DepartmentObjectives WHERE id=${id}`;

        var response = userDB->execute(query);

        if (response is sql:ExecutionResult) {
            return true;
        } else {
            return error("Failed to delete department objective");
        }
    }

    resource function get createKPI(int userId, string name, string metric, string unit) returns KPI|error {
        sql:ParameterizedQuery query = `INSERT INTO KPIs(userId, name, metric, unit) VALUES(${userId}, ${name}, ${metric}, ${unit})`;
        var response = userDB->execute(query);

        if (response is sql:ExecutionResult) {
            KPI newKPI = {
                id: <int>response.lastInsertId,
                user: {id: userId, firstName: "", lastName: "", role: "Employee"},  // We're only setting the 'id' field here. To fetch other User fields, another DB call is needed.
                name: name,
                metric: metric,
                unit: unit,
                score: () // This is optional and hasn't been provided. Hence it will be nil.
            };
            return newKPI;
        } else {
            return error("Failed to create KPI");
        }
    }

    resource function get updateKPI(int id, int userId, string name, string metric, string unit, float score) returns KPI|error {
        sql:ParameterizedQuery query = `UPDATE KPIs SET userId=${userId}, name=${name}, metric=${metric}, unit=${unit}, score=${score} WHERE id=${id}`;
        var response = userDB->execute(query);

        if (response is sql:ExecutionResult) {
            KPI updatedKPI = {
                id: id,
                user: {id: userId, firstName: "", lastName: "", role: "Employee"},  // Only setting the 'id' field for user. To fetch other User fields, another DB call would be needed.
                name: name,
                metric: metric,
                unit: unit,
                score: score
            };
            return updatedKPI;
        } else {
            return error("Failed to update KPI");
        }
    }

    resource function get deleteKPI(int id) returns boolean|error {
        sql:ParameterizedQuery query = `DELETE FROM KPIs WHERE id=${id}`;
        var response = userDB->execute(query);

        if (response is sql:ExecutionResult) {
            return true;
        } else {
            return error("Failed to delete KPI");
        }
    }

    // Allow Supervisor to approve an Employee's KPIs
    resource function get approveKPI(int supervisorId, int kpiId) returns boolean|error {
        sql:ParameterizedQuery query = `UPDATE KPIs SET approved=true WHERE id=${kpiId} AND userId IN (SELECT id FROM Users WHERE supervisorId=${supervisorId})`;
        var response = userDB->execute(query);

        if (response is sql:ExecutionResult) {
            return true;
        } else {
            return error("Failed to approve KPI");
        }
    }

    // Allow Supervisor to grade an Employee's KPIs
    resource function get gradeKPI(int supervisorId, int kpiId, float grade) returns boolean|error {
        sql:ParameterizedQuery query = `UPDATE KPIs SET grade=${grade} WHERE id=${kpiId} AND userId IN (SELECT id FROM Users WHERE supervisorId=${supervisorId})`;
        var response = userDB->execute(query);

        if (response is sql:ExecutionResult) {
            return true;
        } else {
            return error("Failed to grade KPI");
        }
    }
    // Allow Employee to update their own KPIs
    resource function get updateMyKPI(int userId, int kpiId, string name, string metric, string unit) returns KPI|error {
        sql:ParameterizedQuery query = `UPDATE KPIs SET name=${name}, metric=${metric}, unit=${unit} WHERE id=${kpiId} AND userId=${userId}`;
        var response = userDB->execute(query);

        if (response is sql:ExecutionResult) {
            KPI updatedKPI = {
                id: kpiId,
                user: {id: userId, firstName: "", lastName: "", role: "Employee"},
                name: name,
                metric: metric,
                unit: unit
            };
            return updatedKPI;
        } else {
            return error("Failed to update KPI");
        }
    }

    //Authentication
    resource function get login(string firstName, string lastName, string email, string password) returns string|error { // Login function

        sql:ParameterizedQuery saltQuery = `SELECT salt FROM UserAuthentication WHERE email = ${email}`; // Get the salt associated with this email.
        stream<record {|string salt;|}, sql:Error?> saltStream = userDB->query(saltQuery); // The salt is stored in a separate table.

        record {|record {|string salt;|} value;|}? saltResult = check saltStream.next(); // Get the salt from the stream.

        if (saltResult is record {|record {|string salt;|} value;|}) { // Check if the salt was retrieved successfully.
            string salt = saltResult.value.salt;

            // Hash the provided password using the retrieved salt
            string hashedPassword = hashPassword(password, salt);

            // Now check if a user with the provided details and the hashed password exists
            sql:ParameterizedQuery authQuery = `SELECT U.id, U.firstName, U.lastName, U.jobTitle, U.position, U.role, U.departmentId, UA.email, UA.hashedPassword, UA.salt FROM Users U INNER JOIN UserAuthentication UA ON U.id = UA.userId WHERE U.firstName = ${firstName} AND U.lastName = ${lastName} AND UA.email = ${email} AND UA.hashedPassword = ${hashedPassword}`;
            stream<record {|int id; string firstName; string lastName; string? jobTitle; string? position; string role; int? departmentId; string email; string hashedPassword; string salt;|}, sql:Error?> resultStream = userDB->query(authQuery);

            record {|record {|int id; string firstName; string lastName; string? jobTitle; string? position; string role; int? departmentId; string email; string hashedPassword; string salt;|} value;|}? result = check resultStream.next();

            if (result is record {|record {|int id; string firstName; string lastName; string? jobTitle; string? position; string role; int? departmentId; string email; string hashedPassword; string salt;|} value;|}) {

                return "Login successful!";
            } else {
                return error("Authentication failed");
            }
        } else {
            return error("Authentication failed");
        }
    }

    resource function get register(string firstName, string lastName, string email, string password, string jobTitle, string position, string role, int departmentId) returns string|error {
        // Generate a random salt
        string salt = check generateRandomSalt();

        // Hash the password using the salt
        string hashedPassword = hashPassword(password, salt);

        // First, insert the user into the Users table.
        sql:ParameterizedQuery insertUserQuery = `INSERT INTO Users (firstName, lastName, jobTitle, position, role, departmentId, email) VALUES (${firstName}, ${lastName}, ${jobTitle}, ${position}, ${role}, ${departmentId}, ${email})`;
        var userInsertResponse = userDB->execute(insertUserQuery);
        if (userInsertResponse is sql:ExecutionResult) {
            // Get the userId generated by the previous insertion
            string|int? userId = userInsertResponse.lastInsertId;

            if (userId is int) {
                // Now insert into the UserAuthentication table
                sql:ParameterizedQuery authQuery = `INSERT INTO UserAuthentication (userId, email, hashedPassword, salt) VALUES(${userId}, ${email}, ${hashedPassword}, ${salt})`;
                var authInsertResponse = userDB->execute(authQuery);

                if (authInsertResponse is sql:ExecutionResult) { // If the insertion was successful, return a success message
                    return "Registration successful!";
                } else {
                    log:printError("Error during registration in UserAuthentication", authInsertResponse);
                    return error("Registration failed");
                }
            } else {
                log:printError("Error getting the userId after inserting user");
                return error("Registration failed");
            }
        } else {
            log:printError("Error during registration in Users table", userInsertResponse);
            return error("Registration failed");
        }
    }

}

function generateRandomSalt() returns string|error { // Generate a random salt
    string chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    string salt = "";
    int saltLength = 8; // length of the salt you want to generate

    foreach int i in 1 ..< saltLength {
        int randomIndex = check random:createIntInRange(0, chars.length() - 1);
        salt += chars[randomIndex];
    }

    return salt;
}

function hashPassword(string password, string salt) returns string {

    return password + salt; // Simply concatenate the password and salt
}

