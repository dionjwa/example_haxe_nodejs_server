package workflow.server.services.serviceB;

class ServiceB
{
	@rpc({alias:'fooB'})
	public function fooB(input :String) :Promise<String>
	{
		return Promise.promise('$input processed by B');
	}

	public function new() {}
}