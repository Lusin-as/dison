interface DISONManagementAppI{
	command error_t registerTask(uint8_t taskid, uint8_t sensingtype, uint16_t period);
	event void registerDone(uint8_t taskid, bool response);
	command void configure(uint8_t cmd, uint16_t value);
	command void callLog(uint16_t period);
	command error_t reset();
}
