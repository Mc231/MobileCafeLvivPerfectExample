import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import PerfectRequestLogger

let logger = RequestLogger()
var routes = Routes(baseUri: "api/v1/")

struct RequestFilter: HTTPRequestFilter {
	
	let authorizationHeader = "1a1e27"
	
	func filter(request: HTTPRequest, response: HTTPResponse, callback: (HTTPRequestFilterResult) -> ()) {
		
		if request.header(.authorization) == authorizationHeader {
			callback(.continue(request, response))
		}else{
			response.setBody(string: "Forbidden")
			response.status = .forbidden
			callback(.halt(request, response))
		}
	}
}

struct User: Codable {
	let name: String
	let email: String
	let hobby: String
}

struct CreateUserResponse: Codable {
	let token:String
	let user: User
}

struct UpdateUserResponse: Codable {
	let result: Bool
	let user: User?
}

struct DeleteUserResponse: Codable {
	let result: Bool
}

// Array of all users
var allUsers = [String: User]()

func createUser(request: HTTPRequest) throws -> CreateUserResponse {
	do {
		let user: User = try request.decode()
		let token = UUID().string
		allUsers[token] = user
		return .init(token: token, user:user)
	} catch {
		throw HTTPResponseError(status: .badRequest, description: "Invalid parameters")
	}
}

func updateUser(request: HTTPRequest) throws -> UpdateUserResponse {
	do {
		guard let token = request.param(name: "token") else {
			throw HTTPResponseError(status: .badRequest, description: "Invalid token passed")
		}
		
		let user: User = try request.decode()
		
		if allUsers[token] != nil {
			allUsers[token] = user
			return .init(result: true, user: user)
		}else{
			return .init(result: false, user: nil)
		}
	} catch {
		throw HTTPResponseError(status: .badRequest, description: "Invalid parameters")
	}
}

func deleteUser(request: HTTPRequest) throws -> DeleteUserResponse {
	
	guard let token = request.param(name: "token") else {
		throw HTTPResponseError(status: .badRequest, description: "Invalid token passed")
	}
	
	return .init(result: allUsers.removeValue(forKey: token) != nil)
}

routes.add(TRoute(method: .post, uri: "users", handler: createUser))
routes.add(TRoute(method: .put, uri: "users", handler: updateUser))
routes.add(TRoute(method: .delete, uri: "users", handler: deleteUser))

let server = HTTPServer()
server.serverName = "Mobile Cafe"
server.serverPort = 8080
server.addRoutes(routes)
server.setRequestFilters([(logger, .high), (RequestFilter(), .high)])
server.setResponseFilters([(logger, .low)])

do {
	try server.start()
} catch {
	fatalError("Error lunching server \(error)")
}



