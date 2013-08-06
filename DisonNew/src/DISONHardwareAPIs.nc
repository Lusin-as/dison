#include "DISON.h"

module DISONHardwareAPIs {
	provides interface DISONManagementHardwareI[uint8_t client];
	
	uses {
		//Radio interfaces
		//interface AMPacket;
		interface AMSend;
		interface Receive;
		interface SplitControl as AMControl;
		interface DISONManagementPacket;
		interface LowPowerListening;
#if defined (PLATFORM_TELOSB)
		interface CC2420Packet;
#elif defined (TOSSIM)
		interface TossimPacket;
#endif

		//Power interfaces
		interface Read<uint16_t>;
		interface Timer<TMilli> as SleepTimer;
		interface DISONManagementComI;
	}
}
implementation{
	
	bool sendBusy;
	uint8_t current_client;
	
	event void AMControl.startDone(error_t error){
		
	}
	
	event void AMControl.stopDone(error_t error){
		dbg("Management", "Stop radio\n");
	}
	
	command int8_t DISONManagementHardwareI.getRSSI[uint8_t client](message_t* msg)
	{
#if defined (TOSSIM)
         return call TossimPacket.strength(msg);
#elif defined (PLATFORM_TELOSB)
         return call CC2420Packet.getRssi(msg);
#else
		 return 0;
#endif
	}
	
	
	command error_t DISONManagementHardwareI.broadcastBeacon[uint8_t client](message_t *msg, uint8_t len){
		if (!sendBusy)
		{
			if (call AMSend.send(AM_BROADCAST_ADDR, msg, len) == SUCCESS)
			{
				sendBusy = TRUE;
				call DISONManagementComI.logPacket(L_MANA_PKTS, 1);
				call DISONManagementComI.logBytes(L_MANA_PKTS, len);
			}	
		}
		return SUCCESS;
	}
	
	command error_t DISONManagementHardwareI.readResource[uint8_t client](){
		call Read.read();
		current_client = client;
		return SUCCESS;
	}
	
	command error_t DISONManagementHardwareI.setLocalWakeUpInterval[uint8_t client](uint32_t interval){
		call LowPowerListening.setLocalWakeupInterval(interval);
		return SUCCESS;
	}
	
	command error_t DISONManagementHardwareI.setNodeSleep[uint8_t client](uint16_t period){
		call AMControl.stop();
		call SleepTimer.startOneShot(period*60000 + DEFAULT_MIN_INTERVAL);
		return SUCCESS;
	}
	
	command error_t DISONManagementHardwareI.unicastBeacon[uint8_t client](am_addr_t dst, message_t *msg, uint8_t len){
		if (!sendBusy)
		{
			if (call AMSend.send(dst, msg, len) == SUCCESS)
			{
				sendBusy = TRUE;
				call DISONManagementComI.logPacket(L_MANA_PKTS, 1);
				call DISONManagementComI.logBytes(L_MANA_PKTS, len);
			}	
		}
		return SUCCESS;
	}
	
	
	event void AMSend.sendDone(message_t *msg, error_t error){
		sendBusy = FALSE;
	}

	event message_t * Receive.receive(message_t *msg, void *payload, uint8_t len){
		uint8_t client = call DISONManagementPacket.getType(msg);
		call DISONManagementComI.logPacket(L_MANA_PKTS, 1);
		call DISONManagementComI.logBytes(L_MANA_PKTS, len);
		if (client != 0)
		{
			signal DISONManagementHardwareI.recieveBeacon[client](msg, payload, len);
		}
		return msg;
	}

	default event message_t * DISONManagementHardwareI.recieveBeacon[uint8_t client](message_t *msg, void *payload, uint8_t len) {
    	return msg;
  	}
  	
  	default event void DISONManagementHardwareI.readResourceDone[uint8_t client](error_t result, uint16_t data)
  	{
  	}
  	
  	event void Read.readDone(error_t result, uint16_t val){
  		dbg("Management", "Voltage level: %d %d\n", val, current_client);
  		signal DISONManagementHardwareI.readResourceDone[current_client](result, val);
  	}
  	
  	event void SleepTimer.fired(){
  		call AMControl.start();
  	}
  	
}
