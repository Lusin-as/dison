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
  * Implement LEACH clustering algorithm
  * @author Trang Cao Minh
  */

#include <Timer.h>
#include "DISON.h"

module Leach{
	provides {
		interface Init;
		interface StdControl;
	}
	uses {
		interface Timer<TMilli> as SetupNetworkTimer;
		interface Timer<TMilli> as SendADVTimer;
		interface Timer<TMilli> as SendJoinRequestTimer;
		interface Random;
		
		interface DISONManagementHardwareI;
		interface DISONManagementPacket;
		interface DISONManagementUtilityI;
		interface AMPacket;
		interface Leds;
	}
}
implementation{
	
	int round;

	double roundDuration;
	double currentRoundtrip;

	bool isCH;
	bool wasCHinLastRounds;
	double chProb;

	int CHaddr;
	float CHRSSI;

	int advSend;

	uint32_t currentInterval;
    double rnd;
    
    double computeClusterHeadProbability();
    
    message_t sendbuf;
    dison_management_msg_t* pld;
    
	command error_t Init.init() {
		round = -1;
		isCH = FALSE;
		wasCHinLastRounds = TRUE;
		currentInterval = LEACH_MIN_INTERVAL;
		return SUCCESS;
	}
	
	command error_t StdControl.start(){
		call SetupNetworkTimer.startOneShot(ELECTION_START_TIME);
		return SUCCESS;
	}
	
	command error_t StdControl.stop(){

		return SUCCESS;	
	}
	
	double computeClusterHeadProbability()
	{
		if(wasCHinLastRounds)
			return 0;
		
		return chProb / (1 - (round % (int)(1/chProb)));
	}
	
	event void SetupNetworkTimer.fired(){
		isCH = FALSE;
		CHaddr = TOS_NODE_ID;
		CHRSSI = -200;
		chProb = 0.3;
		advSend = 0;
		currentRoundtrip = 0;
		call DISONManagementUtilityI.clearMembers();
		
		round++;
		if (round % LEACH_MAX_ROUND == 0)
			wasCHinLastRounds = FALSE;
		
		rnd = (double)(call Random.rand32()) / RAND_MAX;
		dbg("LEACH", "%f %f\n", rnd, computeClusterHeadProbability());
		call Leds.led1Toggle();
		if (rnd > computeClusterHeadProbability() || TOS_NODE_ID == SINK_ID) {
			isCH = TRUE;
			wasCHinLastRounds = TRUE;
			rnd = (double)(call Random.rand32()) / RAND_MAX;
			currentInterval =  LEACH_MIN_INTERVAL + (int)(LEACH_MIN_INTERVAL*rnd/2);
			dbg("LEACH", "Node %d Round %d I am elected to be CH. Interval to send ADV %d\n", 
			TOS_NODE_ID, round, currentInterval);
			call SendADVTimer.startOneShot(currentInterval);
		}
		else
		{
			rnd = (double)(call Random.rand32()) / RAND_MAX;
			currentInterval =  2*LEACH_MIN_INTERVAL + (int)(LEACH_MIN_INTERVAL*rnd*3/2);
			dbg("LEACH", "Node %d Round %d Start Join Request timer. Interval %d\n", 
			TOS_NODE_ID, round, currentInterval);
			call SendJoinRequestTimer.startOneShot(currentInterval);
		}
		
	}
	
	event void SendADVTimer.fired(){
		uint8_t sz;
		pld = (dison_management_msg_t*)sendbuf.data;
		pld->type = ELECTION_MSG;
		pld->subtype = M_LEACH_ADV;
		pld->size = 0;
		sz = 3*(uint8_t)sizeof(nx_uint8_t) + pld->size;
		call DISONManagementHardwareI.broadcastBeacon(&sendbuf, sz);
		advSend++;
		if (advSend < LEACH_ADV_MAX_SEND) {
			rnd = (double)(call Random.rand32()) / RAND_MAX;
			currentInterval = LEACH_MIN_INTERVAL + (int)(LEACH_MIN_INTERVAL*rnd/2);
			dbg("LEACH", "Node %d Round %d (%d) I am elected to be CH. Interval to send ADV %d\n", 
			TOS_NODE_ID, round, advSend, currentInterval);
			call SendADVTimer.startOneShot(currentInterval);
		}
		else
		{
			if (isCH)
			{
				dbg("LEACH", "Finally node %d is CH\n", TOS_NODE_ID);
				call DISONManagementUtilityI.setManagementRole(GROUP_MANAGER_ROLE);
			}
			else
				dbg("LEACH", "Finally node %d has CH is %d\n", TOS_NODE_ID, CHaddr);
		}
	}
	
	event void SendJoinRequestTimer.fired(){
		uint8_t sz;
		pld = (dison_management_msg_t*)sendbuf.data;
		pld->type = ELECTION_MSG;
		pld->subtype = M_LEACH_JOIN_REQ;
		pld->size = 0;
		sz = 3*(uint8_t)sizeof(nx_uint8_t) + pld->size;
		call DISONManagementHardwareI.unicastBeacon(CHaddr, &sendbuf, sz);
		
		advSend++;
		if (advSend < LEACH_ADV_MAX_SEND)
		{
			rnd = (double)(call Random.rand32()) / RAND_MAX;
			currentInterval = LEACH_MIN_INTERVAL + (int)(LEACH_MIN_INTERVAL*rnd/2);
			dbg("LEACH", "Node %d Round %d Start Join Request timer. Interval %d\n", 
			TOS_NODE_ID, round, currentInterval);
			call SendJoinRequestTimer.startOneShot(currentInterval);
		}
		else
		{
			if (isCH)
			{
				call DISONManagementUtilityI.setManagementRole(GROUP_MANAGER_ROLE);
				dbg("LEACH", "Finally node %d is CH\n", TOS_NODE_ID);
			}
			else
				dbg("LEACH", "Finally node %d has CH is %d\n", TOS_NODE_ID, CHaddr);
		}
	}
	
	
	event void DISONManagementHardwareI.readResourceDone(error_t result, uint16_t data){
		
	}
	
	event message_t * DISONManagementHardwareI.recieveBeacon(message_t *msg, void *payload, uint8_t len){
		int8_t rssi;
		uint8_t type = call DISONManagementPacket.getSubType(msg);
		rssi = call DISONManagementHardwareI.getRSSI(msg);
		dbg("LEACH", "Type %d\n", type);
		switch (type)
		{
			case M_LEACH_ADV:
				dbg("LEACH", "Node %d receives an ADV beacon RSSI: %d \n", TOS_NODE_ID, rssi);
				if (!isCH && rssi > CHRSSI) {
					CHaddr = call AMPacket.source(msg);
					CHRSSI = rssi;
				}
				break;
			case M_LEACH_JOIN_REQ:
				if (isCH) {
					dbg("LEACH", "Node %d receives an JOIN_REQUEST beacon \n", TOS_NODE_ID);
					call DISONManagementUtilityI.addMember(call AMPacket.source(msg));
				}
				break;
		}

		return msg;
	}
	
	
}
