#include "Timer.h"
#include "TestDison.h"
#include "DISON.h"
#include "printf.h"

module TestDisonC @safe()
{
	uses {
		interface Boot;
		interface Leds;
		interface Timer<TMilli> as CollectionTimer;
		interface Timer<TMilli> as DebugTimer;
		interface Timer<TMilli> as AutoTestTimer;
	
		//SENSORS
		interface Read<uint16_t> as Temperature;
		interface Read<uint16_t> as Humidity;
		interface Read<uint16_t> as Light;
		
		interface Read<uint16_t> as Voltage;

		interface SplitControl as RadioControl;	
		//Collection Tree Protocol
		interface StdControl as RoutingControl;
		interface RootControl;
		
		interface Send as DataSend;
		interface Receive as DataReceive;
		interface CollectionPacket;
		
		//Serial communication
		interface SplitControl as SerialControl;
		interface Queue<message_t *> as UARTQueue;
	    interface Pool<message_t> as UARTMessagePool;
	    interface AMSend as SerialSend;
	    
	    interface Receive as Snoop;
	   	interface AMSend as LogSerialSend;
	   	interface AMSend as TopoSerialSend;
	    
	    //Dissemination
	    interface StdControl as DisseminationControl;
	    interface DisseminationUpdate<query_t> as QueryRequestUpdate; //for the root
	    interface DisseminationValue<query_t> as QueryRequestValue; // for the motes
	    
	    interface DisseminationUpdate<dison_command_t> as CommandRequestUpdate; //for the root
	    interface DisseminationValue<dison_command_t> as CommandRequestValue; // for the motes
	    
	    interface DisseminationUpdate<dison_auto_test_t> as ATRequestUpdate; //for the root
	    interface DisseminationValue<dison_auto_test_t> as ATRequestValue; // for the motes
		
		//Management
		interface StdControl as ManagementControl;
		interface DISONManagementUtilityI;
		interface DISONManagementAppI;
		interface DISONManagementComI;
		
		interface Receive as LogReceive;
		interface Receive as TopoReceive;

	}
	
}
implementation
{
	task void uartSendTask();
	void sendData();
	static void startCollectingData();
	
	uint8_t reading; /* 0 to NREADINGS */
	
	uint8_t uartlen;
	message_t sendbuf;
	message_t uartbuf;
	bool sendbusy=FALSE, uartbusy=FALSE;
	
	dison_test_t databuf;
	query_t querybuf;
	uint16_t noSamplings;
	bool useDison;
	
	dison_command_t cmd;
	uint8_t currentRound;	//election round
	
	void reset()
	{
		databuf.id = TOS_NODE_ID;
		querybuf.queryID = 0;
		querybuf.queryPeriod = DEFAULT_QUERY_PERIOD;
		querybuf.samplingPeriod = DEFAULT_SAMPLING_PERIOD;
		querybuf.sensingType = SENSOR_TEMPERATURE | SENSOR_HUMIDITY;
		useDison = FALSE;
		currentRound = 0;
		call Leds.set(0);
	}
	
	event void Boot.booted()
	{
		reset();
		
		if (call RadioControl.start() != SUCCESS)
			call DISONManagementUtilityI.reportProblem(RADIO_PROB);

#ifdef USE_DISON
		if (USE_DISON == 1)
			useDison = TRUE;
#endif
		
		call DisseminationControl.start();
    }
    
    void sendData()
    {
    	int i;
    	call Leds.led0Toggle();
		if (!sendbusy)
		{
			dison_test_t *o = (dison_test_t *)call DataSend.getPayload(&sendbuf, sizeof(dison_test_t));
			databuf.queryID = querybuf.queryID;
			memcpy(o, &databuf, sizeof(databuf));
			if (call DataSend.send(&sendbuf, sizeof(databuf)) == SUCCESS)
				sendbusy = TRUE;
		}
		databuf.count++;
		reading = 0;
		for (i = 0;i < NREADINGS;i++)
		{
			databuf.readings[i] = 0;
		}
    }
    
    event void CollectionTimer.fired(){
    	dbg("Application", "%d %d\n", querybuf.queryPeriod*60000 / querybuf.samplingPeriod, noSamplings);
    	if (noSamplings > querybuf.queryPeriod*60000 / querybuf.samplingPeriod)
    	{
    		if (reading > 0)
    			sendData();
    		call CollectionTimer.stop();
    		call DISONManagementAppI.callLog(1);
    	}
    	else
    	{
	    	if (reading == NREADINGS)
	    	{
	    		sendData();
	    	}
	    	/*if (querybuf.sensingType % 2)
    			call Temperature.read();
    		else
    			call Humidity.read();*/
    		call Voltage.read();
    	}
    	
    	noSamplings++;
    }
    

	//SENSOR
    event void Temperature.readDone(error_t result, uint16_t val){
    	if (reading < NREADINGS)
    		databuf.readings[reading++] = val;
    	/*if (querybuf.sensingType / 2)
    		call Humidity.read();*/
    }
    
    event void Humidity.readDone(error_t result, uint16_t val){
    	if (reading < NREADINGS + 1)
    		databuf.readings[reading + NREADINGS - 1] = val;
    }
    
    event void Light.readDone(error_t result, uint16_t val){
    	
    }
    
    event void Voltage.readDone(error_t result, uint16_t val){
    	if (reading < NREADINGS)
    		databuf.readings[reading++] = val;
    }
    
    
    static void startCollectingData() {
    	if (call CollectionTimer.isRunning()) call CollectionTimer.stop();
    	noSamplings = 0;
    	if (querybuf.samplingPeriod == 0 || querybuf.queryPeriod == 0 || querybuf.sensingType == 0)
    		return;
    		
   		call CollectionTimer.startPeriodic(querybuf.samplingPeriod);
    	reading = 0;
    }

	//COMMUNICATION
	event void RadioControl.startDone(error_t error){
		
		call SerialControl.start();
	}
	
	event void RadioControl.stopDone(error_t error){
		
	}
	
	event void SerialControl.startDone(error_t error){
		if (TOS_NODE_ID == SINK_ID)
			call RootControl.setRoot();
#ifdef TOSSIM
		call DebugTimer.startOneShot(DEBUG_TIME);
		call RoutingControl.start();
		if (useDison)
			call ManagementControl.start();
#endif
	}
	
	event void SerialControl.stopDone(error_t error){
		
	}
	
	
	event void DataSend.sendDone(message_t *msg, error_t error){
		if (error == SUCCESS)
		{
			call DISONManagementComI.logPacket(L_APP_PKTS, 1);
			call DISONManagementComI.logBytes(L_APP_PKTS, sizeof(databuf));
		}
		sendbusy = FALSE;
	}
			
	event message_t * DataReceive.receive(message_t *msg, void *payload, uint8_t len){
		dison_test_t* in = (dison_test_t*)payload;
		dison_test_t* out;
		
#ifdef TOSSIM
		am_addr_t src;
		src = call CollectionPacket.getOrigin(msg);
		dbg("Application", "Receive collection data from node: %d at time %s \n", 
		src, sim_time_string());
#endif
		
		if (uartbusy == FALSE) {
			out = call SerialSend.getPayload(&uartbuf, sizeof(dison_test_t));
			 if (len != sizeof(dison_test_t) || out == NULL) {
			 	return msg;
			 }
			 else {
			 	memcpy(out, in, sizeof(dison_test_t));
			 	uartlen = sizeof(dison_test_t);
			 	post uartSendTask();
			 }
		} else {
			// The UART is busy; queue up messages and service them when the
			// UART becomes free.
			message_t *newmsg = call UARTMessagePool.get();
			if (newmsg == NULL) {
				// drop the message on the floor if we run out of queue space.
				call DISONManagementUtilityI.reportProblem(SERIAL_PROB);
				return msg;
			}
			//Serial port busy, so enqueue.
			out = call SerialSend.getPayload(newmsg, sizeof(dison_test_t));
			if (out == NULL) {
				return msg;
			}
			memcpy(out, in, sizeof(dison_test_t));
			
			if (call UARTQueue.enqueue(newmsg) != SUCCESS) {
				// drop the message on the floor and hang if we run out of
				// queue space without running out of queue space first (this
				// should not occur).
				call UARTMessagePool.put(newmsg);
				call DISONManagementUtilityI.reportProblem(SERIAL_PROB);
				return msg;
			}
		}
		return msg;
	}
	
	event void SerialSend.sendDone(message_t *msg, error_t error){
		uartbusy = FALSE;
		if (call UARTQueue.empty() == FALSE) {
			// We just finished a UART send, and the uart queue is
			// non-empty.  Let's start a new one.
			message_t *queuemsg = call UARTQueue.dequeue();
			if (queuemsg == NULL) {
#ifdef USE_DISON				
				call DISONManagementUtilityI.reportProblem(SERIAL_PROB);
#endif
				return;
			}
			memcpy(&uartbuf, queuemsg, sizeof(message_t));
			if (call UARTMessagePool.put(queuemsg) != SUCCESS) {
#ifdef USE_DISON
				call DISONManagementUtilityI.reportProblem(SERIAL_PROB);
#endif
				return;
			}
			post uartSendTask();
		}
	}

	task void broadcastQuery()
	{
		call QueryRequestUpdate.change(&querybuf);
	}
	
	task void broadcastCmd()
	{
		call CommandRequestUpdate.change(&cmd);
	}
	
	event message_t * Snoop.receive(message_t *msg, void *payload, uint8_t len){
		dison_user_request_t* req = (dison_user_request_t*)payload;
		if (len == sizeof(dison_user_request_t))
		{
			switch (req->type)
			{
				case QUERY_REQUEST: 
				{
					querybuf.queryID++;
					querybuf.sensingType = (uint8_t)req->params[0];
					querybuf.samplingPeriod = req->params[1];
					querybuf.queryPeriod = req->params[2];
					post broadcastQuery();
					break;	
				}
				case COMMAND_REQUEST:
				{
					switch (req->params[0])
					{
						case CMD_RESET_NETWORK:
							cmd.type = CMD_RESET_NETWORK;
							cmd.size = 0;
							post broadcastCmd();
							break;
						case CMD_GET_TOPO:
							cmd.type = CMD_GET_TOPO;
							cmd.size = 0;
							post broadcastCmd();
							break;
					}
					break;
				}
				case AUTOTEST_REQUEST:
				{
					dison_auto_test_t areq;
					areq.queryID = querybuf.queryID + 1;
					areq.sensingType = (uint8_t)req->params[0];
					areq.samplingPeriod = req->params[1];
					areq.queryPeriod = req->params[2];
					areq.useDison = (uint8_t)req->params[3];
					call ATRequestUpdate.change(&areq);
					break;
				}
			}
		}
		return msg;
	}
	
	task void uartSendTask() {

		if (uartlen == sizeof(dison_test_t))
		{
			if (call SerialSend.send(0xffff, &uartbuf, uartlen) != SUCCESS) {
			} else {
				uartbusy = TRUE;
			}
		}
		else if (uartlen == sizeof(dison_stats_t))
		{
			if (call LogSerialSend.send(0xffff, &uartbuf, uartlen) != SUCCESS) {
				call DISONManagementUtilityI.reportProblem(SERIAL_PROB);
			} else {
				uartbusy = TRUE;
			}
		}
		else
		{
			call Leds.led2Toggle();
			if (call TopoSerialSend.send(0xffff, &uartbuf, uartlen) != SUCCESS) {
				call DISONManagementUtilityI.reportProblem(SERIAL_PROB);
			} else {
				uartbusy = TRUE;
			}
		}
	}
	
	event void QueryRequestValue.changed(){
		query_t* query = (query_t*)call QueryRequestValue.get();
		memcpy(&querybuf, query, sizeof(query_t));
		call RoutingControl.start();
		if (useDison)
			call DISONManagementAppI.registerTask(query->queryID, query->sensingType, query->queryPeriod);
		else
			startCollectingData();
	}
	
	event void DISONManagementAppI.registerDone(uint8_t taskid, bool response){
		if (response)
		{
			startCollectingData();
		}
		else
		{
			if (call CollectionTimer.isRunning()) call CollectionTimer.stop();
			call DISONManagementAppI.callLog(querybuf.queryPeriod);
		}
	}
	
	event message_t * LogReceive.receive(message_t *msg, void *payload, uint8_t len){
		dison_stats_t *in;
		dison_stats_t *out;
		in = (dison_stats_t*)payload;
		
		dbg("Management", "Receives a log packet from %d %d %d %d %d %d\n", 
		in->id, in->app_sent_pkts, in->mana_pkts, in->forwarding_pkts, in->routing_pkts, in->mgAddr);

		if (uartbusy == FALSE) {
			out = call LogSerialSend.getPayload(&uartbuf, len);
			 if (len != in->size || out == NULL) {
			 	return msg;
			 }
			 else {
			 	memcpy(out, in, len);
			 	uartlen = len;
			 	post uartSendTask();
			 }
		} else {
			// The UART is busy; queue up messages and service them when the
			// UART becomes free.
			message_t *newmsg = call UARTMessagePool.get();
			if (newmsg == NULL) {
				// drop the message on the floor if we run out of queue space.
				call DISONManagementUtilityI.reportProblem(SERIAL_PROB);
				return msg;
			}
			//Serial port busy, so enqueue.
			out = call LogSerialSend.getPayload(newmsg, len);
			if (out == NULL) {
				return msg;
			}
			memcpy(out, in, len);
			
			if (call UARTQueue.enqueue(newmsg) != SUCCESS) {
				// drop the message on the floor and hang if we run out of
				// queue space without running out of queue space first (this
				// should not occur).
				call UARTMessagePool.put(newmsg);
				call DISONManagementUtilityI.reportProblem(SERIAL_PROB);
				return msg;
			}
		}
		return msg;
	}
	
	event void LogSerialSend.sendDone(message_t *msg, error_t error){
		uartbusy = FALSE;

		if (call UARTQueue.empty() == FALSE) {
			// We just finished a UART send, and the uart queue is
			// non-empty.  Let's start a new one.
			message_t *queuemsg = call UARTQueue.dequeue();
			if (queuemsg == NULL) {
#ifdef USE_DISON				
				call DISONManagementUtilityI.reportProblem(SERIAL_PROB);
#endif
				return;
			}
			memcpy(&uartbuf, queuemsg, sizeof(message_t));
			if (call UARTMessagePool.put(queuemsg) != SUCCESS) {
#ifdef USE_DISON
				call DISONManagementUtilityI.reportProblem(SERIAL_PROB);
#endif
				return;
			}
			post uartSendTask();
		}
	}
	
	event void DebugTimer.fired(){
		if (useDison)
			call DISONManagementAppI.registerTask(querybuf.queryID, querybuf.sensingType, querybuf.queryPeriod);
		else
			startCollectingData();
		//call DISONManagementAppI.configure(CMD_GET_TOPO, 1);	
	}
	
	event void AutoTestTimer.fired(){
		if (useDison)
			call DISONManagementAppI.registerTask(querybuf.queryID, querybuf.sensingType, querybuf.queryPeriod);
		else
			startCollectingData();
			
	}
	
	event void CommandRequestValue.changed(){
		dison_command_t* cmdrq = (dison_command_t*)call CommandRequestValue.get();
		if (cmdrq->type == CMD_RESET_NETWORK)
		{
			if (call CollectionTimer.isRunning())
				call CollectionTimer.stop();
			call RoutingControl.stop();
			reset();
			call DISONManagementAppI.reset();
			return;	
		}
		if (cmdrq->type == CMD_GET_TOPO)
		{
			call DISONManagementAppI.configure(cmdrq->type, 1);
		}
	}
	
	event void ATRequestValue.changed(){
		dison_auto_test_t* areq = (dison_auto_test_t*)call ATRequestValue.get();
		querybuf.queryID = areq->queryID;
		querybuf.samplingPeriod = areq->samplingPeriod;
		querybuf.queryPeriod = areq->queryPeriod;
		querybuf.sensingType = areq->sensingType;
		useDison = areq->useDison;
		call Leds.set(0);
		call DISONManagementUtilityI.setRegisterState(FALSE);
		if (useDison && querybuf.queryID % 4 == 1)
		{
			call ManagementControl.stop();
			call ManagementControl.start();
		}
		call RoutingControl.start();	
		call AutoTestTimer.startOneShot(AUTO_TEST_TIME);
	}
	
	event message_t * TopoReceive.receive(message_t *msg, void *payload, uint8_t len){
		dison_topo_t *in;
		dison_topo_t *out;
		in = (dison_topo_t*)payload;
		dbg("Management", "Receive a topo msg\n");

		if (uartbusy == FALSE) {
			out = call TopoSerialSend.getPayload(&uartbuf, len);
			 if (len != sizeof(dison_topo_t) || out == NULL) {
			 	return msg;
			 }
			 else {
			 	memcpy(out, in, len);
			 	uartlen = len;
			 	post uartSendTask();
			 }
		} else {
			// The UART is busy; queue up messages and service them when the
			// UART becomes free.
			message_t *newmsg = call UARTMessagePool.get();
			if (newmsg == NULL) {
				// drop the message on the floor if we run out of queue space.
				call DISONManagementUtilityI.reportProblem(SERIAL_PROB);
				return msg;
			}
			//Serial port busy, so enqueue.
			out = call TopoSerialSend.getPayload(newmsg, len);
			if (out == NULL) {
				return msg;
			}
			memcpy(out, in, len);
			
			if (call UARTQueue.enqueue(newmsg) != SUCCESS) {
				// drop the message on the floor and hang if we run out of
				// queue space without running out of queue space first (this
				// should not occur).
				call UARTMessagePool.put(newmsg);
				call DISONManagementUtilityI.reportProblem(SERIAL_PROB);
				return msg;
			}
		}
		return msg;
	}
	
	event void TopoSerialSend.sendDone(message_t *msg, error_t error){
		uartbusy = FALSE;

		if (call UARTQueue.empty() == FALSE) {
			// We just finished a UART send, and the uart queue is
			// non-empty.  Let's start a new one.
			message_t *queuemsg = call UARTQueue.dequeue();
			if (queuemsg == NULL) {
#ifdef USE_DISON				
				call DISONManagementUtilityI.reportProblem(SERIAL_PROB);
#endif
				return;
			}
			memcpy(&uartbuf, queuemsg, sizeof(message_t));
			if (call UARTMessagePool.put(queuemsg) != SUCCESS) {
#ifdef USE_DISON
				call DISONManagementUtilityI.reportProblem(SERIAL_PROB);
#endif
				return;
			}
			post uartSendTask();
		}
	}

	
}
