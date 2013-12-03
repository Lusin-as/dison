/*
 * Copyright (c) 2013, Universitat Pompeu Fabra.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 	- Redistributions of source code must retain the above copyright
 * 	- notice, this list of conditions and the following disclaimer.
 * 	- Redistributions in binary form must reproduce the above copyright
 * 	  notice, this list of conditions and the following disclaimer in the
 * 	  documentation and/or other materials provided with the distribution.
 * 	- Neither the name of the Universitat Pompeu Fabra nor the 
 * 	  names of its contributors may be used to endorse or promote products 
 * 	  derived from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL UNIVERSITAT POMPEU FABRA BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
 
 /**
  * @author Trang Cao Minh
  */

#ifndef TEST_DISON_H
#define TEST_DISON_H

enum {
	AM_DISON_TEST = 0x90,			//Collecting data message
	AM_DISON_USER_REQUEST = 0x91,	//User request message
	AM_DISON_STATS = 0x92,
	AM_DISON_TOPO = 0x93,
	
	SINK_ID = 0,
	NREADINGS = 1,
	DEFAULT_SAMPLING_PERIOD = 5000,
	DEFAULT_QUERY_PERIOD = 5,
	NUM_SENSORS = 2,
	
	QUERY_REQUEST_DIS_KEY = 0x30,
	COMMAND_DIS_KEY = 0x31,
	AUTO_TEST_DIS_KEY = 0x32,
	
	//Sleep/awake duty cycle
	DEFAULT_SLEEP_DUTY_CYCLE = 2000,
	DEFAULT_AWAKE_DUTY_CYCLE = 8000,
	
	LOG_SEND_TIME = 10000,
	DEBUG_TIME = 240000,
	DEFAULT_MIN_INTERVAL = 5000,
	LOG_RETRY_MAX = 3,
	
	ELECTION_CYCLE_TIME = 1,	//Before each query request, start election process again
	MAX_RUN_TIMES = 2,
};

enum {
	SENSOR_TEMPERATURE = 0x1,
	SENSOR_HUMIDITY = 0x2,
	SENSOR_LIGHT = 0x4
};

typedef nx_struct {
	nx_uint16_t queryID;
	nx_uint8_t sensingType;
	nx_uint16_t samplingPeriod;
	nx_uint16_t queryPeriod;
	//nx_uint8_t priority; reserved
} query_t;

typedef nx_struct dison_test {
	nx_uint16_t queryID;
	nx_uint16_t id; /* Mote id of sending mote. */
	nx_uint16_t count; /* The readings are samples count * NREADINGS onwards */
	nx_uint16_t readings[NREADINGS];
} dison_test_t;

/*
	Structure of message from the user sent over the network by the gateway
	List of requests
	================
	type (8 bits)
	
	QUERY_REQUEST
*/

enum {
	QUERY_REQUEST = 1,
	COMMAND_REQUEST = 2,
	AUTOTEST_REQUEST = 3,
	
	CMD_SET_AWAKE_DUTY_CYCLE = 1,
	CMD_RESET_NETWORK = 2,
	CMD_GET_TOPO = 3,
	
	AUTO_TEST_TIME = 300000,
	MAX_PARAMS = 10
};

typedef nx_struct dison_user_request {
	nx_uint16_t dstId;
	nx_uint8_t type;
	nx_uint8_t noParams;
	nx_uint16_t params[MAX_PARAMS];
} dison_user_request_t;

typedef nx_struct dison_stats {
	nx_uint16_t id;
	nx_uint8_t size;
	nx_uint32_t app_sent_pkts;
	nx_uint32_t mana_pkts;
	nx_uint32_t forwarding_pkts;
	nx_uint32_t routing_pkts;
	nx_uint16_t mgAddr;
	nx_uint32_t app_sent_bytes;
	nx_uint32_t mana_bytes;
	nx_uint32_t forwarding_bytes;
	nx_uint32_t routing_bytes;
} dison_stats_t;

typedef nx_struct dison_command {
	nx_uint8_t type;
	nx_uint8_t size;
} dison_command_t;

typedef nx_struct dison_auto_test {
	nx_uint16_t queryID;
	nx_uint8_t sensingType;
	nx_uint16_t samplingPeriod;
	nx_uint16_t queryPeriod;
	nx_uint8_t useDison;
} dison_auto_test_t;

typedef nx_struct dison_topo {
	nx_uint16_t id;
	nx_uint8_t noNodes;
	nx_uint16_t nodeList[25];
} dison_topo_t;

#endif /* TEST_DISON_H */
