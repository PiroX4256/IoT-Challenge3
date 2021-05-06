#include "Timer.h"
#include "Challenge3.h"

#include "printf.h"

module Challenge3C
{
	uses {
		interface Leds;
		interface Boot;
		interface Receive;
		interface AMSend;
		interface Timer<TMilli> as MilliTimer;
		interface Packet;
		interface SplitControl as AMControl;
	}
	
}

implementation {
	message_t packet;
	
	bool locked;
	uint16_t counter = 0;
	
	event void Boot.booted() {
		call AMControl.start();
	}
	
	event void AMControl.startDone(error_t err) {
		if(err == SUCCESS) {
			uint16_t timer_period;
			switch(TOS_NODE_ID) {
				case 1:
					timer_period = FREQ1;
					break;
				case 2:
					timer_period = FREQ2;
					break;
				case 3:
					timer_period = FREQ3;
					break;
				default:
					timer_period = 10000;
			}
			printf("STARTUP\n");
			printfflush();
			call MilliTimer.startPeriodic(timer_period);
		}
		else {
			call AMControl.start();
		}
	}
	
	event void AMControl.stopDone(error_t err) {
		//do nothing
		dbg("Ho finito\n");
	}
	
	event void MilliTimer.fired() {
		counter++;
		printf("Challenge3 Timer fired, counter is %u\n", counter);
		printfflush();
		if(locked) {
			return;
		}		
		else {
			challenge3_msg_t* message = (challenge3_msg_t*)call Packet.getPayload(&packet, sizeof(challenge3_msg_t));
			if (message == NULL) {
				return;
			}
			message->counter = counter;
			message->sender_id = TOS_NODE_ID;
			
			if(call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(challenge3_msg_t)) == SUCCESS) {
				dbg("Challenge3", "Packet sent from %hu with counter %hu\n", TOS_NODE_ID, counter);
				locked = TRUE;
			}
		}
	}
	
	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
		challenge3_msg_t* message_received = (challenge3_msg_t*)payload;
		dbg("Challenge 3", "Packet of length %hhu received from %hu.\n", len, message_received->sender_id);
		if(len != sizeof(challenge3_msg_t)) return bufPtr;
		
		if(message_received->counter%10==0) {
			call Leds.led0Off();
			call Leds.led1Off();
			call Leds.led2Off();
			return bufPtr;
		}
		switch(message_received->sender_id) {
			case 1:
				call Leds.led0Toggle();
				break;
			case 2:
				call Leds.led1Toggle();
				break;
			case 3:
				call Leds.led2Toggle();
				break;
			default:
				dbg("KEK\n");
		}
		return bufPtr;
	}
	
	event void AMSend.sendDone(message_t* bufPtr, error_t error) {
		if(&packet == bufPtr) {
			locked = FALSE;
		}
	}
	
}
