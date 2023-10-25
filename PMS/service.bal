import ballerina/io;
import ballerina/http;
import ballerinax/mongodb;
import ballerina/graphql;

// Define enum UserRole
enum UserRole {
    HOD,
    SUPERVISOR,
    EMPLOYEE
};

// Define record Objective
type Objective record {
    string id;
    string title;
    float weight;
    string description;
};

// Define record KPI
type KPI record {
    string id;
    string title;
    string unit;
    Objective objective;
};

// Define record User
type User record {
    string userId;
    string firstName;
    string lastName;
    string jobTitle;
    string position;
    UserRole role;
    Objective[] objectives;
    float totalScores;
    User supervisor;
    KPI[] kpis;
    float[] scores;
};

// MongoDB Configuration
mongodb:ConnectionConfig mongoConfig = {
    connection: {
        host: "localhost",
        port: 27017,
        auth: {
            username: "",
            password: ""
        },
        options: {
            sslEnabled: false,
            serverSelectionTimeout: 5000
        }
    },
    databaseName: "online-store"
};
mongodb:Client db = check new (mongoConfig);
configurable string productCollection = "";
configurable string userCollection = "";
configurable string databaseName = "";

service /Performance_Managment on new graphql:Listener(8080) {

    resource function getUser (string userId, http:Caller caller) returns User {
        // Authenticate the user
        boolean isAuthenticated = authenticateUser(caller.get("username"), caller.get("password"), UserRole.HOD);
        if (!isAuthenticated) {
            // Return an error or handle unauthorized access
            // For simplicity, let's return an empty user
            return {};
        }
        z
    }

    // Retrieve user details from the database
    User user = check<User>db->findOne(userCollection,{userId:userId});
if (user .userId == ""
 ) {
    // Handle user not found
    // For simplicity, let's return an empty user
    return {};
}

// Log user details
io:println ("User Details: ", user) ;

// Return the user details
return user ;

}

// Resolver for createDepartmentObjective mutation
resource function createDepartmentObjective(string name, string description) returns Objective {
    boolean booleanResult = authenticateUser("userId", "password", UserRole.HOD);
    Objective objective = {
            id: "1",
            title: name,
            weight: 0.0,
            description: description
        };
    check mongoClient->insert("Objectives", objective);
    return objective;
}

// Resolver for deleteDepartmentObjective mutation
resource function deleteDepartmentObjective(string id) returns boolean {
    boolean booleanResult = authenticateUser("userId", "password", UserRole.HOD);
    check mongoClient->deleteOne("Objectives", {_id: id});
    return true;
}

// Resolver for viewEmployeesTotalScores query
resource function viewEmployeesTotalScores(string departmentId) returns float {
    boolean booleanResult = authenticateUser("userId", "password", UserRole.HOD);
    float totalScores = 80.0;
    return totalScores;
}

// Resolver for assignEmployeeToSupervisor mutation
resource function assignEmployeeToSupervisor(string employeeId, string supervisorId) returns boolean {
    boolean booleanResult = authenticateUser("userId", "password", UserRole.HOD);
    check mongoClient->update("Users", {userId: employeeId}, {supervisor: supervisorId});
    return true;
}

// Resolver for approveEmployeeKPIs mutation
resource function approveEmployeeKPIs(string employeeId) returns boolean {
    check authenticateUser("userId", "password", UserRole.SUPERVISOR);
    check mongoClient->update("Users", {userId: employeeId}, {kpiStatus: "approved"});
    return true;
}

// Resolver for deleteEmployeeKPIs mutation
resource function deleteEmployeeKPIs(string employeeId) returns boolean {
    boolean booleanResult = authenticateUser("userId", "password", UserRole.SUPERVISOR);
    check mongoClient->update("Users", {userId: employeeId}, {kpi: null});
    return true;
}

// Resolver for updateEmployeeKPIs mutation
resource function updateEmployeeKPIs(string employeeId, float score) returns boolean {
    boolean booleanResult = authenticateUser("userId", "password", UserRole.SUPERVISOR);
    check mongoClient->update("Users", {userId: employeeId}, {kpiScore: score});
    return true;
}

// Resolver for viewEmployeeScores query
resource function viewEmployeeScores(string supervisorId) returns float[] {
    check authenticateUser("userId", "password", UserRole.SUPERVISOR);
    float[] scores = [85.0, 90.0, 75.0];
    return scores;
}

// Resolver for gradeEmployeeKPIs mutation
resource function gradeEmployeeKPIs(string employeeId, float score) returns float {
    check authenticateUser("userId", "password", UserRole.SUPERVISOR);
    check mongoClient->update("Users", {userId: employeeId}, {kpiGrade: score});
    return score;
}

// Resolver for createEmployeeKPI mutation
resource function createEmployeeKPI(string employeeId, string title, string unit, string objectiveId) returns KPI {
    check authenticateUser("userId", "password", UserRole.EMPLOYEE);

    Objective objective = check <Objective>mongoClient->findOne("Objectives", {_id: objectiveId});

    KPI kpi = {
            id: "1",
            title: title,
            unit: unit,
            objective: objective
        };
    check mongoClient->insert("KPIs", kpi);
    return kpi;
}

}

// Function to authenticate user
function authenticateUser(string userId, string password, UserRole requiredRole) returns boolean {
    // Implement authentication logic (e.g., check credentials and role)
    // Return true if authentication is successful, else false
    return true; // Placeholder, replace with actual logic
}

