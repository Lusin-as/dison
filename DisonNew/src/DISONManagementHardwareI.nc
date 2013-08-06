#include <AM.h>

//Management functions and events related to hardware

interface DISONManagementHardwareI{
	
	command error_t readResource();
	event void readResourceDone(error_t result, uint16_t data);
	
	command error_t broadcastBeacon(message_t* msg, uint8_t len);
	command error_t unicastBeacon(am_addr_t dst, message_t* msg, uint8_t len);
	event message_t* recieveBeacon(message_t* msg, void* payload, uint8_t len);
	
	command error_t setNodeSleep(uint16_t period);
	command error_t setLocalWakeUpInterval(uint32_t interval);
	
	command int8_t getRSSI(message_t* msg);
}