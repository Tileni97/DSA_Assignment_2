import ballerina/http;


public class GraphQLClient {
    private http:Client httpClient;


    private json mockUser = {};
    private json mockUsers = [];
    private json mockDepartment = {};
    private json mockDepartments = [];
    private json mockDepartmentObjective = {};
    private json mockDepartmentObjectives = [];
    private json mockKPI = {};
    private json mockKPIs = [];

    public function init() returns error? {
        self.httpClient = check new("http://localhost:8080");
        self.initializeMockData();
    }

    // Mock Data
    private function initializeMockData() {
        self.mockUser = {
            "id": "7",
            "firstName": "Markus",
            "lastName": "Shindingeni",
            "jobTitle": "Cleaner",
            "position": "Senior",
            "role": "Employee",
            "department": {
                "id": "5",
                "name": "Engineering"
            },
            "kpis": [
                {
                    "id": "k1",
                    "name": "Completed Projects"
                }
            ]
        };

        self.mockUsers = [
            self.mockUser,
            {
                "id": "8",
                "firstName": "Morale",
                "lastName": "Smith",
                "role": "Supervisor"
            }
        ];

        self.mockDepartmentObjective = {
            "id": "",
            "name": "Improve Efficiency",
            "weight": 1.5,
            "department": {
                "id": "5",
                "name": "Engineering"
            },
            "relatedKPIs": [
                {
                    "id": "k1",
                    "name": "Completed Projects"
                }
            ]
        };

        self.mockDepartmentObjectives = [
            self.mockDepartmentObjective,
            {
                "id": "",
                "name": "Reduce Bugs",
                "weight": 1.0,
                "department": {
                    "id": "5",
                    "name": "QA"
                },
                "relatedKPIs": [
                    {
                        "id": "k2",
                        "name": "Identified Issues"
                    }
                ]
            }
        ];


    self.mockKPI = {
        "id": "k1",
        "user": {
            "id": "1",
            "firstName": "John",
            "lastName": "Doe"
        },
        "name": "Completed Projects",
        "metric": "Number of Projects",
        "unit": "Count",
        "score": 5.0,
        "relatedObjectives": [self.mockDepartmentObjective]
    };

    self.mockKPIs = [
        self.mockKPI,
        {
            "id": "k2",
            "user": {
                "id": "2",
                "firstName": "Jane",
                "lastName": "Smith"
            },
            "name": "Identified Issues",
            "metric": "Number of Issues",
            "unit": "Count",
            "score": 3.5,
            "relatedObjectives": [self.mockDepartmentObjective] // Assuming you want the same objective linked here
        }
    ];

    self.mockDepartment = {
        "id": "101",
        "name": "Engineering",
        "hod": self.mockUser,
        "objectives": [
            {
                "id": "o1",
                "name": "Increase Productivity"
            }
        ],
        "users": [self.mockUser]
    };

    self.mockDepartments = [self.mockDepartment];
    }






    // Queries

    public function getUser(string id) returns json|error {
        string query = string `{
            "query": "{ user(id: \"${id}\") { id, firstName, lastName, jobTitle, position, role, department { id, name }, kpis { id, name } } }"
        }`;
        return self.graphqlQuery(query);
    }

    public function getAllUsers() returns json|error {
        string query = "{\"query\": \"{ users { id, firstName, lastName, role } }\"}";
        return self.graphqlQuery(query);
    }

    public function getDepartment(string id) returns json|error {
        string query = "{\"query\": \"{ department(id: \"" + id + "\") { id, name, hod { id, firstName, lastName }, objectives { id, name }, users { id, firstName, lastName } } }\"}";
        return self.graphqlQuery(query);
    }

    public function getAllDepartments() returns json|error {
        string query = "{\"query\": \"{ departments { id, name } }\"}";
        return self.graphqlQuery(query);
    }

    public function getDepartmentObjective(string id) returns json|error {
        string query = "{\"query\": \"{ departmentObjective(id: \"" + id + "\") { id, name, weight, department { id, name }, relatedKPIs { id, name } } }\"}";
        return self.graphqlQuery(query);
    }

    public function getAllDepartmentObjectives() returns json|error {
        string query = "{\"query\": \"{ departmentObjectives { id, name, weight } }\"}";
        return self.graphqlQuery(query);
    }

    public function getKPI(string id) returns json|error {
        string query = "{\"query\": \"{ kpi(id: \"" + id + "\") { id, user { id, firstName, lastName }, name, metric, unit, score, relatedObjectives { id, name } } }\"}";
        return self.graphqlQuery(query);
    }

    public function getAllKPIs() returns json|error {
        string query = "{\"query\": \"{ kpis { id, name, metric, unit, score } }\"}";
        return self.graphqlQuery(query);
    }

    // Mutations
    public function createUser(string firstName, string lastName, string jobTitle, string position, string role, string departmentId) returns json|error {
        string mutation = "{\"query\": \"mutation { createUser(firstName: \"" + firstName + "\", lastName: \"" + lastName + "\", jobTitle: \"" + jobTitle + "\", position: \"" + position + "\", role: " + role + ", departmentId: \"" + departmentId + "\") { id, firstName, lastName } }\"}";
        return self.graphqlQuery(mutation);
    }

    public function updateUser(string id, string firstName, string lastName, string jobTitle, string position, string role, string departmentId) returns json|error {
        string mutation = "{\"query\": \"mutation { updateUser(id: \"" + id + "\", firstName: \"" + firstName + "\", lastName: \"" + lastName + "\", jobTitle: \"" + jobTitle + "\", position: \"" + position + "\", role: " + role + ", departmentId: \"" + departmentId + "\") { id, firstName, lastName } }\"}";
        return self.graphqlQuery(mutation);
    }

    public function deleteUser(string id) returns json|error {
        string mutation = "{\"query\": \"mutation { deleteUser(id: \"" + id + "\") }\"}";
        return self.graphqlQuery(mutation);
    }
    
    // Mutations for Departments
    public function createDepartment(string name) returns json|error {
        string mutation = "{\"query\": \"mutation { createDepartment(name: \\\"" + name + "\\\") { id, name } }\"}";
        return self.graphqlQuery(mutation);
    }

    public function updateDepartment(string id, string name) returns json|error {
        string mutation = "{\"query\": \"mutation { updateDepartment(id: \\\"" + id + "\\\", name: \\\"" + name + "\\\") { id, name } }\"}";
        return self.graphqlQuery(mutation);
    }

    public function deleteDepartment(string id) returns json|error {
        string mutation = "{\"query\": \"mutation { deleteDepartment(id: \\\"" + id + "\\\") }\"}";
        return self.graphqlQuery(mutation);
    }

    // Mutations for DepartmentObjectives
    public function createDepartmentObjective(string name, float weight, string departmentId) returns json|error {
        string mutation = "{\"query\": \"mutation { createDepartmentObjective(name: \\\"" + name + "\\\", weight: " + weight.toString() + ", departmentId: \\\"" + departmentId + "\\\") { id, name, weight, department { id, name } } }\"}";
        return self.graphqlQuery(mutation);
    }

    public function updateDepartmentObjective(string id, string name, float weight) returns json|error {
        string mutation = "{\"query\": \"mutation { updateDepartmentObjective(id: \\\"" + id + "\\\", name: \\\"" + name + "\\\", weight: " + weight.toString() + ") { id, name, weight } }\"}";
        return self.graphqlQuery(mutation);
    }

    public function deleteDepartmentObjective(string id) returns json|error {
        string mutation = "{\"query\": \"mutation { deleteDepartmentObjective(id: \\\"" + id + "\\\") }\"}";
        return self.graphqlQuery(mutation);
    }

    // Mutations for KPIs
    public function createKPI(string userId, string name, string metric, string unit) returns json|error {
        string mutation = "{\"query\": \"mutation { createKPI(userId: \\\"" + userId + "\\\", name: \\\"" + name + "\\\", metric: \\\"" + metric + "\\\", unit: \\\"" + unit + "\\\") { id, user { id, firstName, lastName }, name, metric, unit } }\"}";
        return self.graphqlQuery(mutation);
    }

    public function updateKPI(string id, string userId, string name, string metric, string unit, float score) returns json|error {
        string mutation = "{\"query\": \"mutation { updateKPI(id: \\\"" + id + "\\\", userId: \\\"" + userId + "\\\", name: \\\"" + name + "\\\", metric: \\\"" + metric + "\\\", unit: \\\"" + unit + "\\\", score: " + score.toString() + ") { id, user { id, firstName, lastName }, name, metric, unit, score } }\"}";
        return self.graphqlQuery(mutation);
    }

    public function deleteKPI(string id) returns json|error {
        string mutation = "{\"query\": \"mutation { deleteKPI(id: \\\"" + id + "\\\") }\"}";
        return self.graphqlQuery(mutation);
    }

    private function graphqlQuery(string query) returns json|error {
        string payload = string `{"query": ${query}}`;
        http:Response response = check self.httpClient->post("/graphql", payload, headers = { "Content-Type": "application/json" });
        return check response.getJsonPayload();
    }
}
