interface DISONManagementUtilityI{
	command void reportProblem(uint16_t type);
	
	command error_t addMember(am_addr_t node);
	command uint8_t getMemberIndex(am_addr_t node);
	command void clearMembers();
	command error_t updateMember(am_addr_t node, uint8_t nosv, uint8_t cap, uint8_t cellid, uint8_t code);
	
	command error_t addNeighbor(am_addr_t node, uint8_t cell);
	command uint8_t getNeighborIndex(am_addr_t node);
	command uint8_t getNoNeighbors();
	command void clearNeighbors();
	
	command error_t addTask(uint16_t taskid, am_addr_t host);
	command uint8_t getTaskIndex(uint16_t taskid);
	command void clearTasks();
	
	command void setManagementRole(uint8_t);
	command void setManagerAddr(am_addr_t node);
	command void setRegisterState(bool state);
}