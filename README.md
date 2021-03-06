# Example Node.js server built around independent injected services, in Haxe

There are three services ServiceA, ServiceB, ServiceC.

ServiceA and ServiceB run in the main server process.

ServiceC runs in a completely different server.

ServiceA uses ServiceB and ServiceC. The services are injected into ServiceA. ServiceB is the actual ServiceB class, however ServiceC is a proxy class, built at compile time. This is completely opaque to ServiceA, the ServiceC object and the ServiceC proxy object behave exactly the same (call functions, get promises of results).

The actual transport mechanism here are POST requests using JSON-RPC, but this can be transparently changed, the ServiceA object does not know or care what those transport mechanisms are.

## REST API

Run the server:

	docker-compose up

Then try these REST commands:

	curl localhost:9000/api/fooB
	curl localhost:9001/api/fooC
	curl localhost:9000/api/fooAThenC?input=bar

The REST end points are automatically generated.

To get a list of all API methods:

	curl localhost:9000
