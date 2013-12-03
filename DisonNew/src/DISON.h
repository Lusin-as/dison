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
 
#ifndef DISON_H
#define DISON_H

#include <AM.h>

enum {
	AM_DISON_MANAGEMENT_MSG = 0x80,
		
	CONFIGURE_CMD_DIS_KEY = 2,
	
	ELECTION_MSG = 1,
	TASK_REGISTER_MSG = 2,
	
	//TaskRegisterState
	TR_IDLE = 0x01,
	TR_VERIFYING = 0x02,
	TR_SKIPPED = 0x03,
	TR_REFERRING = 0x04,
	TR_APPROVED = 0x05,
	
	TR_MIN_INTERVAL = 1000,
	EXT_LINK_PRI = 10,
	INT_LINK_PRI = 2,
	
	//AM types
	M_TREG = 1,
	M_TREP = 2,
	M_LEACH_ADV = 3,
	M_LEACH_JOIN_REQ = 4,
	M_HELLO = 5,
	M_ROF = 6,
	M_ROC = 7,
	M_SLP = 8,
	M_AR = 9,
	
	//Problem types
	RADIO_PROB = 0x01,
	SERIAL_PROB = 0x02,
	
	MAX_GROUP_MEMBERS = 30,
	ELECTION_PERIOD = 10000,
	
	//MANAGEMENT ROLES
	SELF_MANAGER_ROLE = 1,
	GROUP_MANAGER_ROLE = 2,
	NETWORK_MANAGER_ROLE = 3,
	
	//LOGS
	L_APP_PKTS = 1,
	L_MANA_PKTS = 2,
	L_FORWARDING_PKTS = 3,
	L_ROUTING_PKTS = 4,
	L_MG_ADDR = 5,
	L_MAX_ATTS = 5,
	
	ELECTION_START_TIME = 120000,
	//LEACH protocol
	LEACH_MAX_ROUND = 2,
	LEACH_MIN_INTERVAL = 2000,
	LEACH_ADV_MAX_SEND = 3,
	
	//Proposed protocol
	MAX_HELLO_MSGS = 3,
	HELLO_INTERVAL = 2000,
	MAX_NEIGHBORS = 25,
	ROF_INTERVAL = 10000,
	ROC_INTERVAL = 10000,

#ifdef TOSSIM	
	MAX_ENERGY = 50000,
#else
	MAX_ENERGY = 4096,
#endif
	MAX_TASKS = 5,
	BL_PRI = 10,
	NB_PRI = 5,
	
	FULL_OPERATION = 0x01,
	FORWARDING_ONLY = 0x02,
	SLEEPING = 0x03,
	
	
};

enum {
	STATS_HEADER_SIZE = 16	//4 BYTES (PREAMBLE LENGTH) + 1 BYTE (SFD) + 11 BYTES (MAC HEADER)
};
	
#ifndef CELL_ID
#define CELL_ID 0
#endif

typedef nx_struct dison_management_msg {
	nx_uint8_t type;
	nx_uint8_t subtype;
	nx_uint8_t size;
	nx_uint8_t (COUNT(0) data)[0];
} dison_management_msg_t;

typedef nx_struct  dison_configure_req {
	nx_uint8_t type;
	nx_uint16_t value;
} dison_configure_req_t;

typedef struct {
	am_addr_t node;
	uint8_t noServices;
	uint8_t capability;
	uint8_t cellID;
	uint32_t cellCode;
} group_member_t;

typedef struct {
	uint32_t app_sent_pkts;
	uint32_t mana_pkts;
	uint32_t forwarding_pkts;
	uint32_t routing_pkts;
	uint32_t app_sent_bytes;
	uint32_t mana_bytes;
	uint32_t forwarding_bytes;
	uint32_t routing_bytes;
} comm_log_t;

typedef nx_struct {
	nx_uint8_t cellID;
} dison_hello_msg_t;

typedef nx_struct {
	nx_uint8_t ability;
} dison_rof_msg_t;

//Data types for election process
typedef nx_struct {
	nx_uint16_t taskID;
	nx_uint8_t capability;
	nx_uint32_t cellCode;
	nx_uint8_t cellID;
} dison_treg_msg_t;

typedef nx_struct {
	nx_uint16_t taskID;
	nx_uint8_t noNodes;
	nx_uint16_t nodeList[MAX_NEIGHBORS];
} dison_trep_msg_t;

typedef struct {
	am_addr_t nbID;
	nx_uint8_t cellID;
	bool active;
} election_neighbor_t;

typedef struct {
	uint8_t taskID;
	uint8_t noHost;
	am_addr_t hostNodes[MAX_NEIGHBORS];
} task_entry_t;

typedef struct {
	am_addr_t node;
	uint8_t capability;
	uint32_t code;
	uint8_t cell;
} decide_buffer_entry_t;

#endif /* DISON_H */
