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
PayloadAggregator.start_link([])
PayloadAggregator.start_link([])
PayloadWriter.start_link([])
event = %{device_id: "xxx-xxx-xxx", ctx: "123", value: "50.5"}
PayloadProducer.process(event)


alias IntroGenStage.PayloadProducer2
alias IntroGenStage.PayloadAggregator2
alias IntroGenStage.PayloadWriter2
PayloadProducer2.start_link()
PayloadAggregator2.start_link([name: :A])
PayloadAggregator2.start_link([name: :B])
PayloadWriter2.start_link([publishers: [:A, :B]])
event = %{device_id: "xxx-xxx-xxx", ctx: "123", value: "50.5"}
PayloadProducer2.process(event)


alias IntroGenStage.PayloadProducer3
alias IntroGenStage.PayloadAggregator3
alias IntroGenStage.PayloadWriter3
PayloadProducer3.start_link()
PayloadAggregator3.start_link([name: :A, publishers: [PayloadProducer3], size: 2, id: 0])
PayloadAggregator3.start_link([name: :B, publishers: [PayloadProducer3], size: 2, id: 1])
PayloadWriter3.start_link([publishers: [:A, :B]])
event = %{device_id: "xxx-xxx-xxx", ctx: "123", value: "50.5"}
PayloadProducer3.process(event)
