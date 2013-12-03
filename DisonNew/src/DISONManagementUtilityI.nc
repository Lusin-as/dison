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

interface DISONManagementUtilityI{
	command void reportProblem(uint16_t type);
	
	command error_t addMember(am_addr_t node);
	command uint8_t getMemberIndex(am_addr_t node);
	command void clearMembers();
	command error_t updateMember(am_addr_t node, uint8_t nosv, uint8_t cap, uint8_t cellid, uint32_t code);
	
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