const int num_pins = 16;

// Pin information
int pins[num_pins] = {A0, A1, A2, A3, A4, A5, A6, A7,
                     A8, A9, A10, A11, A12, A13, A14, A15 };

int pin_samuel_ids [2*num_pins] = {3, 2, 1, 0, 7, 6, 5, 4,
                                     11, 10, 9, 8, 15, 14, 13, 12,
                                     19, 18, 17, 16, 23, 22, 21, 20,
                                     27, 26, 25, 24, 31, 30, 29, 28};
int indicator_led = LED_BUILTIN;

int clock_pin = 6;
int data_pin = 7;
int button_pin = 8;


// State information
int states[num_pins * 2];
int next_states[num_pins];
unsigned long times_differences_started[num_pins];
int changes[10][3]; // array of changes, (samuel_pin_number, previus state, new state)
int changes_pos = 0;

// Constants
float upper_thresholds[num_pins];
float lower_thresholds[num_pins];
float upper_threshold_default = 3;
float lower_threshold_default = 2;

int opcode_send_valid_move = 0;

// If state is changed for this amount of time, the state is officially changed
float time_for_new_state = 400;

void setup() {

  // Initialize variables
  for(int i = 0; i < num_pins; i++) {

    // Thresholds
    upper_thresholds[i] = upper_threshold_default;
    lower_thresholds[i] = lower_threshold_default;

    // pin state information
    next_states[i] = 0;
    times_differences_started[i] = 0;
  }

  for (int i = 0; i < num_pins * 2; i++) {
    states[i] = 0;
  }

  pinMode(indicator_led, OUTPUT);
  pinMode(clock_pin, OUTPUT);
  pinMode(data_pin, OUTPUT);
  pinMode(button_pin, INPUT);
  // Set serial timeout, make sure to set for specific serial port                  TODO
  Serial3.setTimeout(100);
  

  // Initialize Serial
  Serial.begin(9600);
  Serial3.begin(9600);
}

void loop() {

  // Check button
  check_button();

  for (int pin_index = 0; pin_index < num_pins; pin_index++) {

    int new_state = state_of_pin(pin_index);
  
    // If new state is different and the change is not yet recorded in next_state, set
    // next_state and start a timer
    if (new_state != states[pin_index] && new_state != next_states[pin_index]) {
      next_states[pin_index] = new_state;
      times_differences_started[pin_index] = millis();
    }

    // Update state from pin on board
    if (next_states[pin_index] != states[pin_index] &&
        millis() - times_differences_started[pin_index] > time_for_new_state) {
      update_state(pin_index, next_states[pin_index]);
    }
  }

  // Update state from other arduino
  listen_for_other_arduino_state_change();

  // Check if a move has been completed
  check_for_move();
}

void listen_for_other_arduino_state_change() {

  String data = Serial3.readStringUntil('\n');
  
  if (!data.equals("")) {
    
    String pin_index_str = data.substring(0, 2);
    String state_str = data.substring(2, 4);
    
    pin_index_str.trim();
    state_str.trim();
    
    int pin_index = pin_index_str.toInt();
    int state = state_str.toInt();

    if (pin_index != 30 || pin_index != 29 || pin_index != 28) {
      update_state(pin_index, state);
    }
  }
  
}

void update_state(int pin_index, int value) {

  int prev = states[pin_index];
  states[pin_index] = value;

  changes[changes_pos][0] = pin_samuel_ids[pin_index];
  changes[changes_pos][1] = prev;
  changes[changes_pos][2] = value;
  changes_pos++;

  Serial.print("Pin ");
  Serial.print(pin_index);
  Serial.print(" state changed, to ");
  Serial.println(states[pin_index]);
}

int state_of_pin(int pin_index) {
  
  float voltage = analogRead(pins[pin_index]) * (5.0 / 1024);

  if (voltage < lower_thresholds[pin_index]) {
    return -1;
  } else if (voltage > upper_thresholds[pin_index]) {
    return 1;
  } else {
    return 0;
  }
}

bool get_number_bit(int num, int bit_loc) {

  return (num & (1 << bit_loc)) >> bit_loc;

//  bool bits[bit_count];
//  for (int i = 0; i < bit_count; i++) {
//    bits[i] = (num & (int)pow(2, i)) != 0;
//  }
//  return bits;
}

void check_for_move() {

  if (changes_pos == 2) {

    // If piece was picked up and put back down
    if (changes[0][0] == changes[1][0]) {

      // Mark as no changes exist
      changes_pos = 0;
    }

    // If a piece was picked up and put down
    else if (changes[0][2] == 0 && (changes[1][2] == -1 || changes[1][2] == 1)) {
      Serial.print("Move: ");
      Serial.print(changes[0][0]);
      Serial.print(" to ");
      Serial.println(changes[1][0]);
      send_move_to_fpga(changes[0][0], changes[1][0]);
      changes_pos = 0;
    }
    
  } 
}

// Send a move over clock and data pins. from and to are in samuel coordinates
void send_move_to_fpga(int from, int to) {
  
  for (int i = 3; i >= 0; i--) {
    //Serial.println(get_number_bit(opcode_send_valid_move, i));
    send_bit(get_number_bit(opcode_send_valid_move, i));
  }

  for (int i = 4; i >= 0; i--) {
    //Serial.println(get_number_bit(from, i));
    send_bit(get_number_bit(from, i));
  }

  for (int i = 4; i >= 0; i--) {
    //Serial.println(get_number_bit(to, i));
    send_bit(get_number_bit(to, i));
  }
}

// Send a bit over derial. bit_num should be 0 or 1
void send_bit(int bit_num) {
  digitalWrite(data_pin, bit_num);
  delay(10);
  digitalWrite(clock_pin, HIGH);
  delay(10);
  digitalWrite(clock_pin, LOW);
}

void check_button() {
  int button_state = digitalRead(button_pin);
  if (button_state == 1) {
//    digitalWrite(data_pin, HIGH);
//    digitalWrite(clock_pin, HIGH);
//    delay(500);
//    digitalWrite(data_pin, LOW);
//    digitalWrite(clock_pin, LOW);

    Serial.println("Resetting changes");
    
    changes_pos = 0;
  }
}
