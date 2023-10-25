import ballerina/http;

public client class GraphQLClient {
    http:Client httpClient;

    public function init() returns error? {
        self.httpClient = check new("http://localhost:8080");
    }

public function getUser(string id) returns User|error {
    string query = string `{
        "query": "{ user(id: "${id}") { id, firstName, lastName, ... } }"
    }`;
    http:Response response = check self.httpClient->post("/graphql", query, headers = { "Content-Type": "application/json" });
    json jsonResponse = check response.getJsonPayload();
    json userJson = check jsonResponse?.data?.user;

    User user = {
        id: (check userJson.id),
        firstName: (check userJson.firstName).toString(),
        lastName: (check userJson.lastName).toString(),
        // ... other fields
    role: "Employee"};

    return user;
}


    // ... Similarly for other functions ...

}

// ... Other types and functions remain the same ...

public type User record {
    int id;
    string firstName;
    string lastName;
    string jobTitle?;
    string position?;
    UserRole role;
    Department department?;
};

public type Department record {
    int id;
    string name;
    int hodId?;
    User hod?;
    DepartmentObjective[] objectives?;
    User[] users?;
};


public type DepartmentObjective record {
    int id;
    string name;
    float weight;
    Department department?;
    KPI[] relatedKPIs?;
};

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