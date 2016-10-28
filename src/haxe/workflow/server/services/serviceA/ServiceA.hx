package workflow.server.services.serviceA;

class ServiceA
{
	@inject
	public var serviceB :workflow.server.services.serviceB.ServiceB;
	@inject
	public var serviceC :workflow.server.services.serviceC.ServiceC;

	public function new() {}

	@rpc({alias:'fooAThenC'})
	public function fooAThenC(input :String) :Promise<String>
	{
		return Promise.promise('$input processed by A')
			.pipe(function(result) {
				return serviceC.fooC(result);
			});
	}

	@rpc({alias:'fooAThenB'})
	public function fooAThenB(input :String) :Promise<String>
	{
		return Promise.promise('$input processed by A')
			.pipe(function(result) {
				return serviceB.fooB(result);
			});
	}
}