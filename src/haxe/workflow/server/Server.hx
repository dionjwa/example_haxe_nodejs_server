package workflow.server;

import haxe.remoting.JsonRpc;

import js.Error;
import js.Node;
import js.node.http.*;
import js.node.Http;
import js.node.stream.Readable;
import js.npm.Express;
import js.npm.express.BodyParser;
import js.npm.JsonRpcExpressTools;

import minject.Injector;

class Server
{
	static function main()
	{
		//Required for source mapping
		js.npm.sourcemapsupport.SourceMapSupport;
		ErrorToJson;

		var injector = new Injector();

		runServer(injector);
		createServices(injector);
	}

	static function createServices(injector :Injector)
	{

	}

	static function createServer(injector :Injector)
	{
		js.Node.process.stdout.setMaxListeners(100);
		js.Node.process.stderr.setMaxListeners(100);

		var app = new Express();
		injector.map(Express).toValue(app);

		untyped __js__('app.use(require("cors")())');

		app.get('/version', function(req, res) {
			res.send("Version 0.0.1");
		});

		//Actually create the server and start listening
		var appHandler :IncomingMessage->ServerResponse->(Error->Void)->Void = cast app;
		var requestErrorHandler = function(err :Dynamic) {
			Log.error({error:err != null && err.stack != null ? err.stack : err, message:'Uncaught error'});
		}
		var server = Http.createServer(function(req, res) {
			appHandler(req, res, requestErrorHandler);
		});

		var closing = false;
		Node.process.on('SIGINT', function() {
			Log.warn("Caught interrupt signal");
			if (closing) {
				return;
			}
			closing = true;
			untyped server.close(function() {
				Node.process.exit(0);
				return Promise.promise(true);
			});
		});

		var PORT :Int = Reflect.hasField(env, 'PORT') ? Std.int(Reflect.field(env, 'PORT')) : 9000;
		server.listen(PORT, function() {
			trace('Listening http://localhost:$PORT');
		});
	}
}
