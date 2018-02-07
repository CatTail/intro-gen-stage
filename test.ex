alias IntroGenStage.Server
{_, server} = Server.start_link()
event = %{device_id: "xxx-xxx-xxx", ctx: "123", value: "50.5"}
Server.process(server, event)

alias IntroGenStage.StateServer
{_, state_server} = StateServer.start_link()
event = %{device_id: "xxx-xxx-xxx", ctx: "123", value: "50.5"}
StateServer.process(state_server, event)
