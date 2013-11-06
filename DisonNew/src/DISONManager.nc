//Provide management functions
#include "DISON.h"
#include "../../TestDison/src/TestDison.h"
#include "printf.h"

module DISONManager{
	provides {
		interface StdControl;
		interface DISONManagementUtilityI;
		interface DISONManagementPacket;
		interface DISONManagementAppI;
		interface DISONManagementComI;
		interface Init;
	}
	uses {
		interface Leds;
		interface Random;
		interface DISONManagementHardwareI;
		interface StdControl as ElectionControl;
		
		interface StdControl as DisseminationControl;
	    interface DisseminationUpdate<dison_configure_req_t> as ConfigureUpdate; //for the root
	    interface DisseminationValue<dison_configure_req_t> as ConfigureValue; // for the motes
	    
	    //Interfaces to sends logs to the sink
	    interface StdControl as RoutingControl;
		interface RootControl;
		
		interface Send as LogSend;
		interface Timer<TMilli> as SendLogTimer;
		
		interface Send as TopoSend;
		interface Timer<TMilli> as SendTopoTimer;
		
		interface Timer<TMilli> as TaskRegisterTimer;
		interface Timer<TMilli> as TaskDecisionTimer;
		interface Timer<TMilli> as TaskNoticeTimer;
		interface Timer<TMilli> as SendSleepBeaconTimer;
		
	    interface AMPacket;
	}
}
implementation{
	
	bool running = FALSE;
	group_member_t members[MAX_GROUP_MEMBERS];
	election_neighbor_t neighbors[MAX_NEIGHBORS];
	task_entry_t tasks[MAX_TASKS];
	uint8_t numMembers = 0;
	uint8_t numNeighbors = 0;
	uint8_t numTasks = 0;
	
	uint8_t managementRole;
	am_addr_t mgAddr;
	uint8_t sensingCap = 3;
	comm_log_t local_log;
	
	message_t sendbuf;
	bool sendbusy=FALSE;
	
	uint32_t currentInterval;
	uint16_t currentVol;
	uint8_t currentAbility;
	uint32_t currentCode;
	uint16_t currentTask;
	uint32_t currentPeriod;
	uint8_t operationState;
	bool isRegister;
	double rnd;
	uint8_t log_retry_counts;
	
	void reset()
	{
		mgAddr = INVALID_ADDR;
		currentTask = 0;
		isRegister = FALSE;
		numMembers = 0;
		numNeighbors = 0;
		numTasks = 0;
		log_retry_counts = 0;
		call DISONManagementComI.initLogs();
		call ElectionControl.stop();
	}
	
	/**
	 * Check if the state of the neighbor in neighbor table
	 */
	bool needNbActive(am_addr_t nb)
	{
		uint8_t idx, i;
		idx = call DISONManagementUtilityI.getMemberIndex(nb);
		if (idx == numNeighbors)
			return FALSE;
		for (i = 0; i < numNeighbors; i++)
		{
			if (i == idx)
				continue;
			if (neighbors[i].cellID == neighbors[idx].cellID)
			{
				return FALSE; 
			}
		}
		return TRUE;
	}
	
	void sendARBeacon(am_addr_t dst)
	{
		uint8_t sz;
		dison_management_msg_t* pld;
		pld = (dison_management_msg_t*)sendbuf.data;
		pld->type = TASK_REGISTER_MSG;
		pld->subtype = M_AR;
		pld->size = 0;
		sz = 3*(uint8_t)sizeof(nx_uint8_t) + pld->size;
		call DISONManagementHardwareI.unicastBeacon(dst, &sendbuf, sz);
	}
	
	
	void calculateAbility()
	{
		int i;
		uint8_t capability = 0;
		uint32_t code = 0;
		uint8_t nbs = call DISONManagementUtilityI.getNoNeighbors();
		
		for (i = 0; i <nbs; i++) {
			if (neighbors[i].active != TRUE)
				continue;
			if (neighbors[i].cellID == CELL_ID)
				capability += INT_LINK_PRI;
			else
				capability += EXT_LINK_PRI;

			code = code | (2 >> (neighbors[i].cellID - 1));
		}
		
		dbg("Management", "Node %d Ability: %d Code: %d\n", TOS_NODE_ID, capability, code);
		currentAbility = capability;
		currentCode = code;
		rnd = (double)(call Random.rand32()) / RAND_MAX;
		currentInterval =  TR_MIN_INTERVAL + (int)(TR_MIN_INTERVAL*rnd/2);
		if (mgAddr != INVALID_ADDR)
		{
			call TaskRegisterTimer.startOneShot(currentInterval);
			call TaskDecisionTimer.startOneShot(2*MAX_NEIGHBORS*TR_MIN_INTERVAL);
		}
		else
		{
			if (managementRole == GROUP_MANAGER_ROLE)
			{
				call DISONManagementUtilityI.addTask(currentTask, TOS_NODE_ID);
			}
			call TaskDecisionTimer.startOneShot(MAX_NEIGHBORS*currentInterval);
		}
			
	}
	
	command error_t Init.init() {
		reset();
		return SUCCESS;
	}
	
	command error_t StdControl.start() {
		if (!running)
		{
			running = TRUE;
			managementRole = SELF_MANAGER_ROLE;
			call ElectionControl.start();
			call DisseminationControl.start();
			if (TOS_NODE_ID == SINK_ID)
				call RootControl.setRoot();
		}
		return SUCCESS;
	}
	
	command error_t StdControl.stop() {
		running = FALSE;
		mgAddr = INVALID_ADDR;
		currentTask = 0;
		isRegister = FALSE;
		numMembers = 0;
		numNeighbors = 0;
		numTasks = 0;
		log_retry_counts = 0;
		call ElectionControl.stop();
		return SUCCESS;
	}
	
	command void DISONManagementUtilityI.reportProblem(uint16_t type)
	{
		switch (type)
		{
			case RADIO_PROB:
				dbg("Management", "Node: %d Problem: Radio\n", TOS_NODE_ID);
				call Leds.set(7); //Turn on all three leds
				break;
		}
	}
	
	command uint8_t DISONManagementPacket.getType(message_t* msg)
	{
		dison_management_msg_t* pld = (dison_management_msg_t*)msg->data;
		if (pld != NULL)
			return (pld->type);
		else
			return 0;
	}
	
	command uint8_t DISONManagementPacket.getSubType(message_t* msg)
	{
		dison_management_msg_t* pld = (dison_management_msg_t*)msg->data;
		if (pld != NULL)
			return (pld->subtype);
		else
			return 0;
	}
	
	event message_t * DISONManagementHardwareI.recieveBeacon(message_t *msg, void *payload, uint8_t len){
		am_addr_t src;
		int i;
		dison_treg_msg_t* tregmsg;
		dison_trep_msg_t* trepmsg;
		dison_management_msg_t* pld;
		uint8_t type = call DISONManagementPacket.getSubType(msg);
		
		src = call AMPacket.source(msg);
		pld = (dison_management_msg_t*)msg->data;
		switch (type)
		{
			case M_TREG:
				dbg("Management", "Node %d receives a TREG message from node %d \n", TOS_NODE_ID, src);
				tregmsg = (dison_treg_msg_t*)pld->data;
				currentTask = tregmsg->taskID;
				call DISONManagementUtilityI.updateMember(src, 1, tregmsg->capability, 
				tregmsg->cellID, tregmsg->cellCode);
				call DISONManagementUtilityI.addTask(currentTask, src);
				if (call TaskDecisionTimer.isRunning() != FALSE)
				{
					rnd = (double)(call Random.rand32()) / RAND_MAX;
					currentInterval =  TR_MIN_INTERVAL + (int)(TR_MIN_INTERVAL*rnd/2);
					call TaskDecisionTimer.startOneShot(MAX_NEIGHBORS*currentInterval*3/2);
				}
				break;
			case M_TREP:
				dbg("Management", "Node %d receives a TREP message from node %d \n", TOS_NODE_ID, src);
				trepmsg = (dison_trep_msg_t*)pld->data;
				for (i = 0; i < trepmsg->noNodes; i++)
				{
					dbg("Managment", "Node %d \n", trepmsg->nodeList[i]);
					if (trepmsg->nodeList[i] == TOS_NODE_ID && TOS_NODE_ID != SINK_ID)
					{
						dbg("Management", "Node %d needs to switch to sleeping state\n",
						TOS_NODE_ID);
						if (call TaskDecisionTimer.isRunning() == TRUE)
							call TaskDecisionTimer.stop();
						rnd = (double)(call Random.rand32()) / RAND_MAX;
						currentInterval =  TR_MIN_INTERVAL + (int)(TR_MIN_INTERVAL*rnd/2);
						call SendSleepBeaconTimer.startOneShot(currentInterval);
						operationState = SLEEPING;
						return msg;
					}	
				} 
				break;
			case M_SLP:
				dbg("Management", "%s Node %d Receives SLP message from node %d\n",
			 __FUNCTION__, TOS_NODE_ID, src);
				if (operationState == SLEEPING)
					break;
				if (needNbActive(src))
					sendARBeacon(src);
				break;
			case M_AR:
				dbg("Management", "%s Node %d Receives AR message from node %d\n",
			 __FUNCTION__, TOS_NODE_ID, src);
			 	operationState = FORWARDING_ONLY;
				break;
		}
		return msg;
	}
	
	
	event void DISONManagementHardwareI.readResourceDone(error_t result, uint16_t data){
		dbg("Management", "Read resource %d \n", data);
		currentVol = data;
		calculateAbility();
	}
	
	uint8_t getMemberIndex(am_addr_t node)
	{
		uint8_t i;
		for (i = 0; i < numMembers; i++) {
            if (members[i].node == node)
                break;
        }
        return i;
	}
	
	command uint8_t DISONManagementUtilityI.getMemberIndex(am_addr_t node) {
		return getMemberIndex(node);
	}
	
	command error_t DISONManagementUtilityI.addMember(am_addr_t node) {
	 	uint8_t idx;
	 	idx = getMemberIndex(node);
	 	if (idx == MAX_GROUP_MEMBERS)
	 	{
	 		//not found and table is full
	 		dbg("Management", "%s FAIL, table full\n", __FUNCTION__);
	 		return FAIL;
	 	}
	 	else if (idx == numMembers) {
	 		atomic {
	 			members[idx].node = node;
	 			numMembers++;
	 		}
	 		dbg("Management", "%s OK, Node %d new entry %d\n", __FUNCTION__, TOS_NODE_ID, node);
	 	} else {
	 		atomic {
	 			members[idx].node = node;
	 		}
	 		dbg("Management", "%s OK, updated entry\n", __FUNCTION__);
	 	}
	 	return SUCCESS;
	}
	
	command void DISONManagementUtilityI.clearMembers() {
		numMembers = 0;	
	}
	
	command error_t DISONManagementUtilityI.updateMember(am_addr_t node, uint8_t nosv, uint8_t cap, uint8_t cellid, uint32_t code){
		uint8_t idx;
	 	idx = getMemberIndex(node);
	 	if (idx == MAX_GROUP_MEMBERS)
	 	{
	 		//not found and table is full
	 		dbg("Management", "%s FAIL, table full\n", __FUNCTION__);
	 		return FAIL;
	 	}
	 	else if (idx == numMembers) {
	 		atomic {
	 			members[idx].node = node;
	 			members[idx].noServices = nosv;
	 			members[idx].capability = cap;
	 			members[idx].cellID = cellid;
	 			members[idx].cellCode = code;
	 			numMembers++;
	 		}
	 		dbg("Management", "%s OK, Node %d new entry %d\n", __FUNCTION__, TOS_NODE_ID, node);
	 	} else {
	 		atomic {
	 			members[idx].noServices = nosv;
	 			members[idx].capability = cap;
	 			members[idx].cellID = cellid;
	 			members[idx].cellCode = code;
	 		}
	 		dbg("Management", "%s OK, updated entry\n", __FUNCTION__);
	 	}
	 	return SUCCESS;
	}
	
	uint8_t getNeighborIndex(am_addr_t node)
	{
		uint8_t i;
		for (i = 0; i < numNeighbors; i++) {
            if (neighbors[i].nbID == node)
                break;
        }
        return i;
	}
	
	command uint8_t DISONManagementUtilityI.getNeighborIndex(am_addr_t node){
		return getNeighborIndex(node);
	}
	
	
	command error_t DISONManagementUtilityI.addNeighbor(am_addr_t node, uint8_t cell){
		uint8_t idx;
	 	idx = getNeighborIndex(node);
	 	if (idx == MAX_NEIGHBORS)
	 	{
	 		//not found and table is full
	 		dbg("Management", "%s FAIL, table full\n", __FUNCTION__);
	 		return FAIL;
	 	}
	 	else if (idx == numNeighbors) {
	 		atomic {
	 			neighbors[idx].nbID = node;
	 			neighbors[idx].cellID = cell;
	 			neighbors[idx].active = TRUE;
	 			numNeighbors++;
	 		}
	 		dbg("Management", "%s OK, Node %d new entry %d\n", __FUNCTION__, TOS_NODE_ID, node);
	 	} else {
	 		atomic {
	 			neighbors[idx].cellID = cell;
	 			neighbors[idx].active = TRUE;
	 		}
	 		dbg("Management", "%s OK, updated entry\n", __FUNCTION__);
	 	}
	 	return SUCCESS;
	}
	
	command uint8_t DISONManagementUtilityI.getNoNeighbors(){
		return numNeighbors;
	}
	
	
	command void DISONManagementUtilityI.clearNeighbors(){
		numNeighbors = 0;
	}
	
	uint8_t getTaskIndex(uint16_t id)
	{
		uint8_t i;
		for (i = 0; i < numTasks; i++) {
            if (tasks[i].taskID == id)
                break;
        }
        return i;
	}
	command uint8_t DISONManagementUtilityI.getTaskIndex(uint16_t id){
		return getTaskIndex(id);
	}
	
	command error_t DISONManagementUtilityI.addTask(uint16_t taskid, am_addr_t host){
		uint8_t idx;
		uint8_t nohost;
	 	idx = getTaskIndex(taskid);
	 	if (idx == MAX_TASKS)
	 	{
	 		dbg("Management", "%s FAIL, table full\n", __FUNCTION__);
	 		return FAIL;
	 	}
	 	else if (idx == numTasks) {
	 		atomic {
	 			tasks[idx].taskID = taskid;
	 			tasks[idx].noHost = 1;
	 			tasks[idx].hostNodes[0] = host;
	 			numTasks++;
	 		}
	 		dbg("Management", "%s OK, Node %d new task %d from host %d\n", 
	 		__FUNCTION__, TOS_NODE_ID, taskid, host);
	 	}
	 	else
	 	{
	 		atomic {
	 			nohost = tasks[idx].noHost;
	 			tasks[idx].hostNodes[nohost] = host;
	 			tasks[idx].noHost++;
	 		}
	 		dbg("Management", "%s OK, Node %d add new host %d of task %d No host %d\n", __FUNCTION__,
	 		TOS_NODE_ID, host, taskid, tasks[idx].noHost);
	 	}
	 	return SUCCESS;
	}
	
	command void DISONManagementUtilityI.clearTasks(){
		numTasks = 0;
	}
	
	
	command void DISONManagementUtilityI.setManagementRole(uint8_t role){
		managementRole = role;
	}
	
	command void DISONManagementUtilityI.setManagerAddr(am_addr_t node){
		mgAddr = node;
	}
	
	command void DISONManagementUtilityI.setRegisterState(bool state){
		isRegister = state;
	}
	
	
	command error_t DISONManagementAppI.registerTask(uint8_t taskid, uint8_t sensingtype, uint16_t period){
		currentPeriod = period;
		if (isRegister)
			return SUCCESS;
		if (sensingtype & sensingCap)
		{
			dbg("Management", "Node has request sensing capability\n");
			call Leds.led0On();
			call DISONManagementHardwareI.readResource();
			currentTask = taskid;
		}
		return SUCCESS;
	}
	
	command void DISONManagementAppI.configure(uint8_t cmd, uint16_t value){
		dison_configure_req_t req;
		req.type = cmd;
		req.value = value;
		dbg("Management", "configure\n");
		call ConfigureUpdate.change(&req);
	}
	
	event void ConfigureValue.changed(){
		dison_configure_req_t* areq = (dison_configure_req_t*)call ConfigureValue.get();
		if (areq->type == CMD_GET_TOPO)
		{
			log_retry_counts = 0;
			rnd = (double)(call Random.rand32()) / RAND_MAX;
			currentInterval = DEFAULT_MIN_INTERVAL + (int)(DEFAULT_MIN_INTERVAL*rnd/2);
			call SendTopoTimer.startOneShot(currentInterval);
		}
	}
	
	command void DISONManagementComI.initLogs(){
		memset(&local_log, 0, sizeof(comm_log_t));
	}
	
	command error_t DISONManagementComI.logPacket(uint8_t type, uint32_t value){
		switch (type)
		{
			case L_APP_PKTS:
				local_log.app_sent_pkts += value;
				break;
			case L_MANA_PKTS:
				local_log.mana_pkts += value;
				break;
			case L_FORWARDING_PKTS:
				local_log.forwarding_pkts += value;
				break;
			case L_ROUTING_PKTS:
				local_log.routing_pkts += value;
		}
		return SUCCESS;	
	}
	
	command error_t DISONManagementComI.logBytes(uint8_t type, uint8_t size){
		switch (type)
		{
			case L_APP_PKTS:
				local_log.app_sent_bytes += size + STATS_HEADER_SIZE;
				break;
			case L_MANA_PKTS:
				local_log.mana_bytes += size + STATS_HEADER_SIZE;
				break;
			case L_FORWARDING_PKTS:
				local_log.forwarding_bytes += size + STATS_HEADER_SIZE;
				break;
			case L_ROUTING_PKTS:
				local_log.routing_bytes += size + STATS_HEADER_SIZE;
				break;
		}
		return SUCCESS;
	}
	
	event void LogSend.sendDone(message_t *msg, error_t error){
		sendbusy=FALSE;
	}

	/**event message_t * LogReceive.receive(message_t *msg, void *payload, uint8_t len){
		uint8_t att;
		uint16_t id;
		uint32_t value;
		dison_stats_t *o;
		o = (dison_stats_t*)payload;
		dbg("Management", "Receives a log packet from %d size %d\n", o->id, len);
		
		return msg;
	}*/
	
	event void SendLogTimer.fired(){
		uint8_t sz;
		/*uint8_t att;
		uint8_t* pa;*/
		dison_stats_t *o;

		dbg("Management", "Send a log packet to sink \n");
		log_retry_counts++;
		
		if (!sendbusy)
		{
			/*sz = (L_MAX_ATTS-1)*(sizeof(uint8_t) + sizeof(uint32_t)) + sizeof(uint8_t)
			+ sizeof(uint8_t) + sizeof(mgAddr) + sizeof(nx_uint16_t);*/
			sz = sizeof(dison_stats_t);
			o = (dison_stats_t *)(call LogSend.getPayload(&sendbuf, sz));
			o->id = TOS_NODE_ID;
			o->size = sz;
			o->app_sent_pkts = local_log.app_sent_pkts;
			o->mana_pkts = local_log.mana_pkts;
			o->forwarding_pkts = local_log.forwarding_pkts;
			o->routing_pkts = local_log.routing_pkts;
			o->mgAddr = mgAddr;
			o->app_sent_bytes = local_log.app_sent_bytes;
			o->mana_bytes = local_log.mana_bytes;
			o->forwarding_bytes = local_log.forwarding_bytes;
			o->routing_bytes = local_log.routing_bytes;

			/*att = L_APP_PKTS;
			pa = &o->data[0];
			memcpy(pa, &att, sizeof(att));
			memcpy(pa+1, &local_log.app_sent_pkts, sizeof(local_log.app_sent_pkts));
			att = L_MANA_PKTS;
			memcpy(pa+5, &att, sizeof(att));
			memcpy(pa+6, &local_log.mana_pkts, sizeof(local_log.mana_pkts));
			att = L_COMM_PKTS;
			memcpy(pa+10, &att, sizeof(att));
			memcpy(pa+11, &local_log.routing_pkts, sizeof(local_log.routing_pkts));
			att = L_MG_ADDR;
			memcpy(pa+15, &mgAddr, sizeof(mgAddr));
			memcpy(pa+17, &att, sizeof(att));*/

			if (call LogSend.send(&sendbuf, o->size) == SUCCESS)
				sendbusy = TRUE;
			if (log_retry_counts < LOG_RETRY_MAX)
			{
				rnd = (double)(call Random.rand32()) / RAND_MAX;
				currentInterval = DEFAULT_MIN_INTERVAL + (int)(DEFAULT_MIN_INTERVAL*rnd/2);
				call SendLogTimer.startOneShot(currentInterval);
			}
		}
	}
	
	command void DISONManagementAppI.callLog(uint16_t period)
	{
		log_retry_counts = 0;
		call SendLogTimer.startOneShot(period*60000 + DEFAULT_MIN_INTERVAL);
	}
	
	command error_t DISONManagementAppI.reset(){
		running = FALSE;
		reset();
		return SUCCESS;
	}
	
	
	event void TaskRegisterTimer.fired(){
		uint8_t sz;
		dison_treg_msg_t tregmsg;
		dison_management_msg_t* pld;
		pld = (dison_management_msg_t*)sendbuf.data;
		pld->type = TASK_REGISTER_MSG;
		pld->subtype = M_TREG;
		pld->size = sizeof(dison_treg_msg_t);
		tregmsg.capability = currentAbility;
		tregmsg.cellCode = currentCode;
		tregmsg.taskID = currentTask;
		tregmsg.cellID = CELL_ID;
		memcpy(&pld->data, &tregmsg, sizeof(dison_treg_msg_t));
		sz = 3*(uint8_t)sizeof(nx_uint8_t) + pld->size;
		dbg("Management", "Send task register to manager %d\n", mgAddr);
		call DISONManagementHardwareI.unicastBeacon(mgAddr,&sendbuf, sz);
	}

	event void TaskDecisionTimer.fired()
	{
		uint8_t tid;
		task_entry_t titem;
		decide_buffer_entry_t buffer[numMembers];
		am_addr_t red_nodes[numMembers];
		int cell, cap, no_redundant_nodes = 0;
		uint8_t i, j, midx, didx, noBufItems = 0;
		uint32_t x, code;
		bool conf = TRUE;
		dison_management_msg_t* pld;
		dison_trep_msg_t trepmsg;
		uint8_t sz = 0;
		tid = call DISONManagementUtilityI.getTaskIndex(currentTask);
		titem = tasks[tid];
		
		dbg("Management", "Decision Timer at node %d fired\n", TOS_NODE_ID);
		dbg("Management", "Task: %d index %d no host: %d Role: %d\n", 
		currentTask, tid, titem.noHost, managementRole);
		if (managementRole == GROUP_MANAGER_ROLE)
		{
			for (i = 0; i < titem.noHost; i++)
			{
				cell = -1;
				cap = -1;
				code = 0;
				if (titem.hostNodes[i] == TOS_NODE_ID)
				{
					cell = CELL_ID;
					cap = currentAbility;
					code = currentCode;
				}
				else
				{
					midx = call DISONManagementUtilityI.getMemberIndex(titem.hostNodes[i]);
					if (midx < numMembers)
					{
						cell = members[midx].cellID;
						cap = members[midx].capability;
						code = members[midx].cellCode;
					}
				}
				
				dbg("Management", "Host %d Cell %d Cap %d Code %d\n", titem.hostNodes[i],
				cell, cap, code);
				if (cell == -1 || cap == -1)
					continue;
					
				for (didx = 0; didx < noBufItems; didx++)
				{
					if (buffer[didx].cell == cell)
						break;
				}

				if (didx == noBufItems)
				{
					buffer[didx].node = titem.hostNodes[i];
					buffer[didx].capability = (uint8_t)cap;
					buffer[didx].code = code;
					buffer[didx].cell = (uint8_t)cell;
					noBufItems++;
				}
				else
				{
					if (code == buffer[didx].code)
					{
						if (cap > buffer[didx].capability)
						{
							red_nodes[no_redundant_nodes] = buffer[didx].node;
							buffer[didx].node = titem.hostNodes[i];
							buffer[didx].capability = (uint8_t)cap;
							buffer[didx].code = code;
							buffer[didx].cell = (uint8_t)cell;
						}
						else {
							red_nodes[no_redundant_nodes] = titem.hostNodes[i];
						}
						no_redundant_nodes++;
					}
					else
					{
						//Check if one node covers other node connection
						x = code & buffer[didx].code;
						if (x == code)
						{
							red_nodes[no_redundant_nodes] = titem.hostNodes[i];
							no_redundant_nodes++;
						}
						else if (x == buffer[didx].code)
						{
							red_nodes[no_redundant_nodes] = buffer[didx].node;
							no_redundant_nodes++;
							buffer[didx].node = titem.hostNodes[i];
							buffer[didx].capability = (uint8_t)cap;
							buffer[didx].code = code;
							buffer[didx].cell = (uint8_t)cell;
						}
						else
						{
							buffer[didx].code = code | buffer[didx].code;
						}
					}
				}
			}
			dbg("Management", "Number of redundant nodes: %d\n", no_redundant_nodes);
			if (no_redundant_nodes > 0)
			{
				j = 0;
		    	for (i = 0; i < no_redundant_nodes; i++)
		    	{
		    		if (red_nodes[i] == TOS_NODE_ID)
		    			conf = FALSE;
		    		else
		    		{
		    			trepmsg.nodeList[j] = red_nodes[i];
		    			j++;
		    		}
		    	}
		    	
		    	if (j > 0)
		    	{
			    	pld = (dison_management_msg_t*)sendbuf.data;
			    	pld->type = TASK_REGISTER_MSG;
			    	pld->subtype = M_TREP;
			    	pld->size = (uint8_t)(sizeof(uint8_t) + sizeof(nx_uint16_t) + j*sizeof(nx_uint16_t));
			    	trepmsg.taskID = currentTask;
			    	trepmsg.noNodes = j;
			    	memcpy(pld->data, &trepmsg, pld->size);
			    	sz = 3*(uint8_t)sizeof(nx_uint8_t) + pld->size;
				    dbg("Management", "%s Node %d Broadcast TREP message\n", __FUNCTION__, TOS_NODE_ID);
				    call DISONManagementHardwareI.broadcastBeacon(&sendbuf, sz);
			    }
			}
		}
		
		if (conf)
		{
			dbg("DisonManager", "Node %d starts collecting data \n", TOS_NODE_ID);
			call TaskNoticeTimer.startOneShot(currentInterval);
			operationState = FULL_OPERATION;
		}
		else
		{
			rnd = (double)(call Random.rand32()) / RAND_MAX;
			currentInterval =  TR_MIN_INTERVAL + (int)(TR_MIN_INTERVAL*rnd/2);
			if (managementRole == GROUP_MANAGER_ROLE || TOS_NODE_ID == SINK_ID) {
				operationState = FORWARDING_ONLY;
				call TaskNoticeTimer.startOneShot(currentInterval);
			}
			else {
				operationState = SLEEPING;
				call SendSleepBeaconTimer.startOneShot(currentInterval);
			}
		}
	}
	
	event void TaskNoticeTimer.fired(){
		bool res = TRUE;
		dbg("Management", "Task Notice Timer \n");
		switch (operationState)
		{
			case SLEEPING:
				dbg("Management", "Node %d switches to sleeping state \n", TOS_NODE_ID);
				res = FALSE;
				call Leds.led2On();
				call DISONManagementHardwareI.setNodeSleep(currentPeriod);
				break;
			case FORWARDING_ONLY:
				dbg("Management", "Node %d switches to forwarding state \n", TOS_NODE_ID);
				res = FALSE;
				break;
			case FULL_OPERATION:
				res = TRUE;
				dbg("Management", "Full Operation \n", TOS_NODE_ID);
				break;
		}
		isRegister = TRUE;
		call Leds.led0Off();
		signal DISONManagementAppI.registerDone(currentTask, res);

	}
	
	event void SendSleepBeaconTimer.fired(){
		uint8_t sz;
		dison_management_msg_t* pld;
		pld = (dison_management_msg_t*)sendbuf.data;
		pld->type = TASK_REGISTER_MSG;
		pld->subtype = M_SLP;
		pld->size = 0;
		sz = 3*(uint8_t)sizeof(nx_uint8_t) + pld->size;
		call DISONManagementHardwareI.broadcastBeacon(&sendbuf, sz);
		rnd = (double)(call Random.rand32()) / RAND_MAX;
		currentInterval =  TR_MIN_INTERVAL + (int)(TR_MIN_INTERVAL*rnd/2);
		call TaskNoticeTimer.startOneShot(currentInterval);
		dbg("Management", "%s Node %d Broadcast SLP message \n", __FUNCTION__, TOS_NODE_ID);
	}

	event void SendTopoTimer.fired(){
		dison_topo_t* pld;
		uint8_t sz;
		int i;
		log_retry_counts++;
		
		if (!sendbusy)
		{
			sz = sizeof(dison_topo_t);
			pld = (dison_topo_t *)(call TopoSend.getPayload(&sendbuf, sz));
			pld->id = TOS_NODE_ID;
			pld->noNodes = numNeighbors;
			for (i = 0; i < numNeighbors; i++)
			{
				pld->nodeList[i] = neighbors[i].nbID;
			}

			if (call TopoSend.send(&sendbuf, sz) == SUCCESS)
				sendbusy = TRUE;

			if (log_retry_counts < LOG_RETRY_MAX)
			{
				rnd = (double)(call Random.rand32()) / RAND_MAX;
				currentInterval = DEFAULT_MIN_INTERVAL + (int)(DEFAULT_MIN_INTERVAL*rnd/2);
				call SendTopoTimer.startOneShot(currentInterval);
			}
		}
	}
	
	event void TopoSend.sendDone(message_t *msg, error_t error){
		sendbusy=FALSE;
		
	}
	
		
}
