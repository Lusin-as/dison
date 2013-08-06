interface DISONManagementUserI{
	command error_t resetQuery(uint16_t query_id);
	command error_t collectLog();
}