

typedef nx_struct challenge3_msg_s {
	nx_uint16_t counter; //counter value
	nx_uint16_t sender_id;
} challenge3_msg_t;

enum {
	AM_RADIO_COUNT_MSG = 6, TIMER_PERIOD_MILLI = 250, FREQ1 = 1000, FREQ2 = 333, FREQ3 = 200,
};
