

interface DISONManagementComI{
	command void initLogs();
	command error_t logPacket(uint8_t type, uint32_t value);
	command error_t logBytes(uint8_t type, uint8_t size);
}