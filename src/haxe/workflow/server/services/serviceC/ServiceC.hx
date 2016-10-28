package workflow.server.services.serviceC;

class ServiceC
{
	@rpc
	public function fooC(input :String) :Promise<String>
	{
		return Promise.promise('$input processed by C');
	}

	public function new() {}
}