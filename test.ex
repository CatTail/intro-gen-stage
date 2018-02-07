alias IntroGenStage.Server
{_, server} = Server.start_link()
event = %{device_id: "xxx-xxx-xxx", ctx: "123", value: "50.5"}
Server.process(server, event)


alias IntroGenStage.StateServer
{_, state_server} = StateServer.start_link()
event = %{device_id: "xxx-xxx-xxx", ctx: "123", value: "50.5"}
StateServer.process(state_server, event)


alias IntroGenStage.Producer
alias IntroGenStage.ProducerConsumer
alias IntroGenStage.Consumer
Producer.start_link()
ProducerConsumer.start_link()
Consumer.start_link()


alias IntroGenStage.PayloadProducer
alias IntroGenStage.PayloadAggregator
alias IntroGenStage.PayloadWriter
PayloadProducer.start_link()
PayloadAggregator.start_link([publishers: [PayloadProducer], name: :A, size: 2, id: 0])
PayloadAggregator.start_link([publishers: [PayloadProducer], name: :B, size: 2, id: 1])
PayloadWriter.start_link([publishers: [:A, :B]])
event = %{device_id: "xxx-xxx-xxx", ctx: "123", value: "50.5"}
PayloadProducer.process(event)
