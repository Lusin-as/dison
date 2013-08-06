#include "TestDison.h"
#include "printf.h"

configuration TestDisonApp{
	
}
implementation{
	components MainC, TestDisonC, LedsC, new TimerMilliC();
	TestDisonC -> MainC.Boot;
	TestDisonC.Leds -> LedsC;
	TestDisonC.CollectionTimer -> TimerMilliC;
	components new TimerMilliC() as DebugTimer;
	components new TimerMilliC() as AutoTestTimer;
	TestDisonC.DebugTimer -> DebugTimer;
	TestDisonC.AutoTestTimer -> AutoTestTimer;
	
	//Demo Sensors
	components new DemoSensorC() as Light;
	components new DemoSensorC() as Temperature;
	components new DemoSensorC() as Humidity;

#ifdef TOSSIM
	components new DemoSensorC() as Voltage;
#else
	components new VoltageC() as Voltage;
#endif
	
	TestDisonC.Light -> Light;
	TestDisonC.Temperature -> Temperature;
	TestDisonC.Humidity -> Humidity;
	
	//Collection Communication
	components CollectionC as Collector;
	components new CollectionSenderC(AM_DISON_TEST);
	
	components ActiveMessageC;

    TestDisonC.RadioControl -> ActiveMessageC;
    TestDisonC.RoutingControl -> Collector;
    TestDisonC.RootControl -> Collector;
    TestDisonC.CollectionPacket -> Collector;
    TestDisonC.DataReceive -> Collector.Receive[AM_DISON_TEST];
    TestDisonC.DataSend -> CollectionSenderC;

	//Serial Commnication    
    components new SerialAMSenderC(AM_DISON_TEST) as SerialDataSender,
    new SerialAMSenderC(AM_DISON_STATS) as SerialLogSender,
    new SerialAMSenderC(AM_DISON_TOPO) as SerialTopoSender;
    components SerialActiveMessageC;
        
   	components new PoolC(message_t, 10) as UARTMessagePoolP,
    new QueueC(message_t*, 10) as UARTQueueP;
    
    TestDisonC.SerialControl -> SerialActiveMessageC;
    TestDisonC.UARTMessagePool -> UARTMessagePoolP;
    TestDisonC.UARTQueue -> UARTQueueP;
    TestDisonC.SerialSend -> SerialDataSender.AMSend;
    TestDisonC.LogSerialSend -> SerialLogSender.AMSend;
    TestDisonC.TopoSerialSend -> SerialTopoSender.AMSend;
    
    components new SerialAMReceiverC(AM_DISON_USER_REQUEST) as SerialRequestReceiver;
	TestDisonC.Snoop -> SerialRequestReceiver;
	
	//Broadcast communication
	components DisseminationC;
	TestDisonC.DisseminationControl -> DisseminationC;
	
	components new DisseminatorC(query_t, QUERY_REQUEST_DIS_KEY) as QueryObj;
    TestDisonC.QueryRequestUpdate -> QueryObj;
    TestDisonC.QueryRequestValue -> QueryObj;
    
    components new DisseminatorC(dison_command_t, COMMAND_DIS_KEY) as CmdObj;
    TestDisonC.CommandRequestUpdate -> CmdObj;
    TestDisonC.CommandRequestValue -> CmdObj;
    
    components new DisseminatorC(dison_auto_test_t, AUTO_TEST_DIS_KEY) as AtObj;
    TestDisonC.ATRequestUpdate -> AtObj;
    TestDisonC.ATRequestValue -> AtObj;
        
    //Management
    components DisonC;
    TestDisonC.ManagementControl -> DisonC;
    TestDisonC.DISONManagementUtilityI -> DisonC;
    TestDisonC.DISONManagementAppI -> DisonC;
    TestDisonC.DISONManagementComI -> DisonC;
    TestDisonC.LogReceive -> DisonC.LogReceive;
    TestDisonC.TopoReceive -> DisonC.TopoReceive;
   	TestDisonC.Voltage -> Voltage;
}
