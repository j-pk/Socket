var http = require('https');

const PORT = 8080;

function handleRequest(request, response) {
	response.end('Connected to Server Path:' + request.url);
}

var server = http.createServer(handleRequest);

server.listen(PORT, function() {
	console.log("Server is listening on: http://localhost:%s", PORT)	
})

