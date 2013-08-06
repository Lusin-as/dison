#include <Timer.h>
#include "DISON.h"

module Election{
	provides {
		interface Init;
		interface StdControl;
	}
	uses {
		interface Timer<TMilli> as ElectionTimer;
		interface Timer<TMilli> as SendHELLOTimer;
		interface Timer<TMilli> as SendROFTimer;
		interface Timer<TMilli> as SendROCTimer;
		interface Random;
		
		interface DISONManagementHardwareI;
		interface DISONManagementPacket;
		interface DISONManagementUtilityI;
		interface AMPacket;
		interface Leds;
	}
}
implementation{
	
	message_t sendbuf;
	dison_management_msg_t* pld;
	uint8_t currentHelloCount;
	uint32_t currentInterval;
	uint16_t currentVol;
	uint8_t currentAbility;
	double rnd;
	uint16_t mgAddr;
	bool isMg;

	void calculateAbility()
	{
		uint8_t ability;
		uint8_t nbs = call DISONManagementUtilityI.getNoNeighbors();
		ability = (uint8_t)(((currentVol*10/MAX_ENERGY)*BL_PRI + nbs*NB_PRI)/(BL_PRI + NB_PRI));
		dbg("Management", "Node %d Ability: %d\n", TOS_NODE_ID, ability);
		if (ability > currentAbility)
		{
			currentAbility = ability;
			rnd = (double)(call Random.rand32()) / RAND_MAX;
			currentInterval =  ROF_INTERVAL + (int)(ROF_INTERVAL*rnd/2);
			call SendROFTimer.startOneShot(currentInterval);
		}
	}
	
	command error_t Init.init() {
		currentHelloCount = 0;
		return SUCCESS;
	}
	
	command error_t StdControl.start(){
		call ElectionTimer.startOneShot(ELECTION_START_TIME);
		return SUCCESS;
	}
	
	command error_t StdControl.stop(){

		return SUCCESS;
	}
	
	event void DISONManagementHardwareI.readResourceDone(error_t result, uint16_t data){
		dbg("Management", "Read resource %d \n", data);
		currentVol = data;
		calculateAbility();
	}
	
	event message_t * DISONManagementHardwareI.recieveBeacon(message_t *msg, void *payload, uint8_t len){
		am_addr_t src;
		uint8_t type = call DISONManagementPacket.getSubType(msg);
		dison_rof_msg_t* rofmsg;
		dison_hello_msg_t* hellomsg;
		
		src = call AMPacket.source(msg);
		pld = (dison_management_msg_t*)msg->data;
		dbg("Election", "Election Type %d\n", type);
		switch (type)
		{
			case M_HELLO:
				hellomsg = (dison_hello_msg_t*)pld->data;
				dbg("Election", "Node %d receives a Hello message from node %d \n", TOS_NODE_ID, src);
				call DISONManagementUtilityI.addNeighbor(src, hellomsg->cellID);
				break;
			case M_ROF:
				if (isMg)
					break;
				rofmsg = (dison_rof_msg_t*)pld->data;
				dbg("Election", "Node %d receives a ROF message from node %d Ability: %d\n", TOS_NODE_ID, src, rofmsg->ability);
				if (currentAbility <= rofmsg->ability)
				{
					if (call SendROFTimer.isRunning() == TRUE)
					{
						call SendROFTimer.stop();		
					}
					currentAbility = rofmsg->ability;
					mgAddr = src;
					rnd = (double)(call Random.rand32()) / RAND_MAX;
					currentInterval =  ROC_INTERVAL + (int)(ROC_INTERVAL*rnd/2);
					call SendROCTimer.startOneShot(currentInterval);
				}
				break;
			case M_ROC:
				call Leds.led0Off();
				call Leds.led1On();
				call DISONManagementUtilityI.setManagementRole(GROUP_MANAGER_ROLE);
				dbg("Election", "Node %d receives a ROC message from node %d \n", TOS_NODE_ID, src);
				break;
		}
		
		return msg;
	}
	
	event void ElectionTimer.fired(){
		currentHelloCount = 0;
		currentAbility = 0;
		mgAddr = INVALID_ADDR;
		isMg = FALSE;
		call Leds.led0On();
		call DISONManagementUtilityI.clearMembers();
		call DISONManagementUtilityI.setManagementRole(SELF_MANAGER_ROLE);
		call DISONManagementUtilityI.setManagerAddr(mgAddr);
		rnd = (double)(call Random.rand32()) / RAND_MAX;
		currentInterval =  HELLO_INTERVAL + (int)(HELLO_INTERVAL*rnd/2);
		call SendHELLOTimer.startOneShot(currentInterval);
	}
	
	event void SendHELLOTimer.fired(){
		uint8_t sz;
		dison_hello_msg_t hello_msg;
		pld = (dison_management_msg_t*)sendbuf.data;
		pld->type = ELECTION_MSG;
		pld->subtype = M_HELLO;
		pld->size = 1;
		hello_msg.cellID = CELL_ID;
		memcpy(&pld->data, &hello_msg, sizeof(nx_uint8_t));
		sz = 3*(uint8_t)sizeof(nx_uint8_t) + pld->size;
		call DISONManagementHardwareI.broadcastBeacon(&sendbuf, sz);

		currentHelloCount++;
		if (currentHelloCount <= MAX_HELLO_MSGS)
		{
			rnd = (double)(call Random.rand32()) / RAND_MAX;
			currentInterval = HELLO_INTERVAL + (int)(HELLO_INTERVAL*rnd/2);
			dbg("Election", "Node %d Round %d start hello timer. Interval %d Cell %d\n", 
			TOS_NODE_ID, currentHelloCount, currentInterval, CELL_ID);
			call SendHELLOTimer.startOneShot(currentInterval);
		}
		else
		{
			call DISONManagementHardwareI.readResource();
		}
	}
	
	event void SendROFTimer.fired(){
		uint8_t sz;
		dison_rof_msg_t rofmsg;
		pld = (dison_management_msg_t*)sendbuf.data;
		pld->type = ELECTION_MSG;
		pld->subtype = M_ROF;
		pld->size = sizeof(nx_uint8_t);
		rofmsg.ability = currentAbility;
		memcpy(&pld->data, &rofmsg, sizeof(nx_uint8_t));
		sz = 3*(uint8_t)sizeof(nx_uint8_t) + pld->size;
		call DISONManagementHardwareI.broadcastBeacon(&sendbuf, sz);
		isMg = TRUE;
		dbg("Election", "%s Node %d Broadcast ROF message \n", __FUNCTION__, TOS_NODE_ID);
	}
	
	event void SendROCTimer.fired(){
		uint8_t sz;
		if (mgAddr == INVALID_ADDR)
		{
			return;
		}
		pld = (dison_management_msg_t*)sendbuf.data;
		pld->type = ELECTION_MSG;
		pld->subtype = M_ROC;
		pld->size = 0;
		sz = 3*(uint8_t)sizeof(nx_uint8_t) + pld->size;
		call DISONManagementHardwareI.unicastBeacon(mgAddr,&sendbuf, sz);
		call DISONManagementUtilityI.setManagerAddr(mgAddr);
		dbg("Election", "%s Node %d Send ROC message to node %d \n", __FUNCTION__, TOS_NODE_ID, mgAddr);
		call Leds.led0Off();
	}
	
	
	
}