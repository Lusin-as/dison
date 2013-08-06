interface DISONManagementPacket{
	command uint8_t getType(message_t* msg);
	command uint8_t getSubType(message_t* msg);
}