package workflow.server;

import haxe.remoting.JsonRpc;
import t9.js.jsonrpc.Routes;

import js.Error;
import js.Node;
import js.node.http.*;
import js.node.Http;
import js.node.express.Express;
import js.node.express.Application;

import minject.Injector;

import workflow.server.services.serviceA.ServiceA;
import workflow.server.services.serviceB.ServiceB;
import workflow.server.services.serviceC.ServiceC;

class Server
{
	static function main()
	{
		//Required for source mapping
		js.npm.sourcemapsupport.SourceMapSupport;

		//Create the ServiceC in its own remote server
		Promise.promise(true)
			.pipe(function(_) {
				return createSeparateServerC();
			})
			.then(function(_) {
				//Create a server for Service A and B, that proxy Service C
				var injector = new Injector();
				createServer(injector);
				createServices(injector);
			});
	}

	static function createSeparateServerC() :Promise<Bool>
	{
		var promise = new DeferredPromise();
		//Create the server specifically for ServiceA
		var app = Express.GetApplication();

		//Actually create the server and start listening
		var appHandler :IncomingMessage->ServerResponse->(Error->Void)->Void = cast app;
		var requestErrorHandler = function(err :Dynamic) {
			trace({error:err != null && err.stack != null ? err.stack : err, message:'Uncaught error'});
		}

		var server = Http.createServer(function(req, res) {
			appHandler(req, res, requestErrorHandler);
		});

		var closing = false;
		Node.process.on('SIGINT', function() {
			trace("Caught interrupt signal");
			if (closing) {
				return;
			}
			closing = true;
			untyped server.close(function() {
				Node.process.exit(0);
				return Promise.promise(true);
			});
		});

		var env :haxe.DynamicAccess<String> = Node.process.env;
		var PORT :Int = env.get('PORT') != null && env.get('PORT') != "" ? Std.parseInt(env.get('PORT')) : 9000;
		PORT++;
		server.listen(PORT, function() {
			trace('Service C listening http://localhost:$PORT');
			promise.resolve(true);
		});

		//Create proxies to Service A and B. These get injected into ServiceC

		var rpcUrl = 'http://localhost:9000/api';

		var proxyServiceA = t9.remoting.jsonrpc.Macros.buildRpcClient(workflow.server.services.serviceA.ServiceA, true)
			.setConnection(new t9.remoting.jsonrpc.JsonRpcConnectionHttpPost(rpcUrl));

		var proxyServiceB = t9.remoting.jsonrpc.Macros.buildRpcClient(workflow.server.services.serviceB.ServiceB, true)
			.setConnection(new t9.remoting.jsonrpc.JsonRpcConnectionHttpPost(rpcUrl));

		//Now create the actual Service C

		var serverContext = new t9.remoting.jsonrpc.Context();

		var serviceC = new ServiceC();
		serverContext.registerService(serviceC);

		app.post('/api', Routes.generatePostRequestHandler(serverContext));
		app.get('/api*', Routes.generateGetRequestHandler(serverContext, '/api'));

		return promise.boundPromise;
	}

	static function createServices(injector :Injector)
	{
		var serverContext = new t9.remoting.jsonrpc.Context();

		var serviceA = new ServiceA();
		serverContext.registerService(serviceA);
		injector.map(ServiceA).toValue(serviceA);

		var serviceB = new ServiceB();
		serverContext.registerService(serviceB);
		injector.map(ServiceB).toValue(serviceB);

		//Create a proxy to Service C, it is injected into Service A and B
		var rpcUrl = 'http://localhost:9001/api';

		var proxyServiceC = t9.remoting.jsonrpc.Macros.buildRpcClient(workflow.server.services.serviceC.ServiceC, true)
			.setConnection(new t9.remoting.jsonrpc.JsonRpcConnectionHttpPost(rpcUrl));
		injector.map(ServiceC).toValue(cast proxyServiceC);

		//Inject last when all are registed
		injector.injectInto(serviceA);
		injector.injectInto(serviceB);

		var app :Application = injector.getValue(Application);
		app.post('/api', Routes.generatePostRequestHandler(serverContext));
		app.get('/api*', Routes.generateGetRequestHandler(serverContext, '/api'));
	}

	static function createServer(injector :Injector)
	{
		var app = Express.GetApplication();
		injector.map(Application).toValue(app);

		untyped __js__('app.use(require("cors")())');

		app.get('/version', function(req, res) {
			res.send("Version 0.0.1");
		});

		//Actually create the server and start listening
		var appHandler :IncomingMessage->ServerResponse->(Error->Void)->Void = cast app;
		var requestErrorHandler = function(err :Dynamic) {
			trace({error:err != null && err.stack != null ? err.stack : err, message:'Uncaught error'});
		}

		var server = Http.createServer(function(req, res) {
			appHandler(req, res, requestErrorHandler);
		});

		var closing = false;
		Node.process.on('SIGINT', function() {
			trace("Caught interrupt signal");
			if (closing) {
				return;
			}
			closing = true;
			untyped server.close(function() {
				Node.process.exit(0);
				return Promise.promise(true);
			});
		});

		var env :haxe.DynamicAccess<String> = Node.process.env;
		var PORT :Int = env.get('PORT') != null && env.get('PORT') != "" ? Std.parseInt(env.get('PORT')) : 9000;
		server.listen(PORT, function() {
			trace('Listening http://localhost:$PORT');

			//Run tests
			var attemptTest = null;
			attemptTest = function() {
				var serviceA :ServiceA = injector.getValue(ServiceA);
				if (serviceA == null) {
					Node.setTimeout(attemptTest, 100);
				} else {
					var inputValue = 'sometest';
					serviceA.fooAThenB(inputValue)
						.pipe(function(resultB) {
							trace('resultB=${resultB}');
							return serviceA.fooAThenC(inputValue)
								.then(function(resultC) {
									trace('resultC=${resultC}');
									// Node.process.exit(0);
								});
						});
				}
			}
			attemptTest();
		});
	}

	static function __init__()
	{
#if js
		untyped __js__("
			if (!('toJSON' in Error.prototype))
				Object.defineProperty(Error.prototype, 'toJSON', {
				value: function () {
					var alt = {};

					Object.getOwnPropertyNames(this).forEach(function (key) {
						alt[key] = this[key];
					}, this);

					return alt;
				},
				configurable: true,
				writable: true
			})
		");
#end
	}
}
