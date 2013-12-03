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
  * @author Trang Cao Minh
  */

#include "DISON.h"

configuration DisonC{
	provides {
		interface StdControl;
		//interface DISONManagementHardwareI;
		interface DISONManagementUtilityI;
		interface DISONManagementAppI;
		interface DISONManagementComI;
		interface Receive as LogReceive;
		interface Receive as TopoReceive;
	}
	//uses interface StdControl as BroadcastControl;

}
implementation{
	components MainC;
	components DISONManager;
	
	MainC.SoftwareInit -> DISONManager.Init;
	
	components new TimerMilliC() as ClusteringTimer;
	
#ifdef LEACH
	components new TimerMilliC() as SendADVTimer;
	components new TimerMilliC() as SendJoinRequestTimer;
#else
	components new TimerMilliC() as SendHELLOTimer;
	components new TimerMilliC() as SendROFTimer;
	components new TimerMilliC() as SendROCTimer;
#endif
	
	components new TimerMilliC() as SendLogTimer;
	components new TimerMilliC() as TaskRegisterTimer;
	components new TimerMilliC() as TaskDecisionTimer;
	components new TimerMilliC() as TaskNoticeTimer;
	components new TimerMilliC() as TaskSendSLPTimer;
	components new TimerMilliC() as SendTopoTimer;

	components RandomC,LedsC;
	DISONManager.Random -> RandomC;
	DISONManager.Leds -> LedsC;
	DISONManager.TaskRegisterTimer -> TaskRegisterTimer;
	DISONManager.TaskDecisionTimer -> TaskDecisionTimer;
	DISONManager.TaskNoticeTimer -> TaskNoticeTimer;
	DISONManager.SendSleepBeaconTimer -> TaskSendSLPTimer;
	components DISONHardwareAPIs;
	
#if defined (PLATFORM_TELOSB)
	components CC2420ActiveMessageC as Radio;
	DISONHardwareAPIs.CC2420Packet -> Radio;
#elif defined (TOSSIM)
	components TossimActiveMessageC as Radio;
	DISONHardwareAPIs.TossimPacket -> Radio;
#endif

	components ActiveMessageC;
	
	components new TimerMilliC() as SleepTimer;
	DISONHardwareAPIs.AMControl -> ActiveMessageC;
	DISONHardwareAPIs.SleepTimer -> SleepTimer;
	DISONHardwareAPIs.DISONManagementComI -> DISONManager;
	
	StdControl = DISONManager;
	DISONManagementUtilityI = DISONManager.DISONManagementUtilityI;
	DISONManagementAppI = DISONManager.DISONManagementAppI;
	DISONManagementComI = DISONManager.DISONManagementComI;
	DISONManager.DISONManagementHardwareI -> DISONHardwareAPIs.DISONManagementHardwareI[TASK_REGISTER_MSG];
	DISONManager.AMPacket -> ActiveMessageC;
	
	components new AMSenderC(AM_DISON_MANAGEMENT_MSG) as ManagementSender, 
	new AMReceiverC(AM_DISON_MANAGEMENT_MSG) as ManagementReceiver;

#ifdef LEACH
	components Leach;
	MainC.SoftwareInit -> Leach;
	DISONManager.ElectionControl -> Leach.StdControl;
	Leach.SetupNetworkTimer -> ClusteringTimer;
	Leach.SendADVTimer -> SendADVTimer;
	Leach.SendJoinRequestTimer -> SendJoinRequestTimer;
	Leach.Random -> RandomC;
	Leach.DISONManagementHardwareI -> DISONHardwareAPIs.DISONManagementHardwareI[ELECTION_MSG];
	Leach.DISONManagementPacket -> DISONManager;
	Leach.AMPacket -> ActiveMessageC;
	Leach.DISONManagementUtilityI -> DISONManager;
	Leach.Leds -> LedsC;
#else
	components Election;
	MainC.SoftwareInit -> Election;
	DISONManager.ElectionControl -> Election.StdControl;
	Election.ElectionTimer -> ClusteringTimer;
	Election.SendHELLOTimer -> SendHELLOTimer;
	Election.SendROFTimer -> SendROFTimer;
	Election.SendROCTimer -> SendROCTimer;
	Election.Random -> RandomC;
	Election.DISONManagementHardwareI -> DISONHardwareAPIs.DISONManagementHardwareI[ELECTION_MSG];
	Election.DISONManagementPacket -> DISONManager;
	Election.AMPacket -> ActiveMessageC;
	Election.DISONManagementUtilityI -> DISONManager;
	Election.Leds -> LedsC;
#endif
	
	DISONHardwareAPIs.AMSend -> ManagementSender;
	DISONHardwareAPIs.Receive -> ManagementReceiver;
	DISONHardwareAPIs.DISONManagementPacket -> DISONManager.DISONManagementPacket;
	
	//Broadcast communication

	components DisseminationC;
	components new DisseminatorC(dison_configure_req_t, CONFIGURE_CMD_DIS_KEY) as ConfigureObj;
	DISONManager.DisseminationControl -> DisseminationC;
    DISONManager.ConfigureUpdate -> ConfigureObj;
    DISONManager.ConfigureValue -> ConfigureObj;
    
    components CollectionC as Collector;
	components new CollectionSenderC(AM_DISON_STATS);
	
    DISONManager.RoutingControl -> Collector;
    DISONManager.RootControl -> Collector;
    LogReceive = Collector.Receive[AM_DISON_STATS];
    DISONManager.LogSend -> CollectionSenderC;
    DISONManager.SendLogTimer -> SendLogTimer;
    
    components new CollectionSenderC(AM_DISON_TOPO) as TopoSend;
    TopoReceive = Collector.Receive[AM_DISON_TOPO];
    DISONManager.TopoSend -> TopoSend;
    DISONManager.SendTopoTimer -> SendTopoTimer;
    
#ifdef TOSSIM
	components new DemoSensorC() as Power;
#else
	components new VoltageC() as Power;
#endif
	DISONHardwareAPIs.Read -> Power;
	
}	

