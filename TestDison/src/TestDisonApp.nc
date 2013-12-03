/*
 * Copyright (c) 2013, Universitat Pompeu Fabra.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 	- Redistributions of source code must retain the above copyright
 * 	- notice, this list of conditions and the following disclaimer.
 * 	- Redistributions in binary form must reproduce the above copyright
 * 	  notice, this list of conditions and the following disclaimer in the
 * 	  documentation and/or other materials provided with the distribution.
 * 	- Neither the name of the Universitat Pompeu Fabra nor the 
 * 	  names of its contributors may be used to endorse or promote products 
 * 	  derived from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL UNIVERSITAT POMPEU FABRA BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
 
 /**
  * A simple application using DISON
  * @author Trang Cao Minh
  */
  
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
