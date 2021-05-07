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
	#ifdef LOGGING
	bool led1 = FALSE, led2 = FALSE, led3 = FALSE;
	#endif
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
					#ifdef LOGGING
					printf("Led Status: %u%u%u\n", led1, led2, led3);
					printfflush();
					#endif
					break;
				case 3:
					timer_period = FREQ3;
					break;
				default:
					//every mote which id is not between 1 and 3
					timer_period = 10000;
			}
			call MilliTimer.startPeriodic(timer_period);
		}
		else {
			call AMControl.start();
		}
	}
	
	event void AMControl.stopDone(error_t err) {
		//do nothing
	}
	
	event void MilliTimer.fired() {
		#ifdef LOGGING
		/*printf("Challenge3 Timer fired, counter is %u\n", counter);
		printfflush();*/
		#endif
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
				locked = TRUE;
			}
		}
	}
	
	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
		challenge3_msg_t* message_received = (challenge3_msg_t*)payload;
		
		if(len != sizeof(challenge3_msg_t)) return bufPtr;
		
		counter++;
		
		#ifdef LOGGING
			/*printf("Counter: %u\n", counter);
			printfflush();*/
		#endif
		
		if(message_received->counter%10==0) {
			call Leds.led0Off();
			call Leds.led1Off();
			call Leds.led2Off();
			#ifdef LOGGING
			printf("Flushing: %u\n", TOS_NODE_ID);
			printfflush();
			led1=FALSE;
			led2=FALSE;
			led3=FALSE;
			if(TOS_NODE_ID == 2) {
				printf("Led Status: %u%u%u\n", led1, led2, led3);
				printfflush();
			}
			#endif
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
				#ifdef LOGGING
				printf("Nothing\n");
				printfflush();
				#endif
		}
		
		#ifdef LOGGING
		switch(message_received->sender_id) {
				case 1:
				if(TOS_NODE_ID == 2) {
					led1 = !led1;
				}
				break;
			case 2:
				if(TOS_NODE_ID == 2) {
					led2 = !led2;
				}
				break;
			case 3:
				if(TOS_NODE_ID == 2) {
					led3 = !led3;
				}
				break;
			default:
				#ifdef LOGGING
				printf("Nothing\n");
				printfflush();
				#endif
		}
		
		if(TOS_NODE_ID==2) {
			printf("Led Status: %u%u%u\n", led1, led2, led3);
			printfflush();
		}
		#endif
		return bufPtr;
	}
	
	event void AMSend.sendDone(message_t* bufPtr, error_t error) {
		if(&packet == bufPtr) {
			locked = FALSE;
		}
	}
	
}

