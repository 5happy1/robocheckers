const int num_pins = 16;

// Pin information
int pins[num_pins] = {A0, A1, A2, A3, A4, A5, A6, A7,
                     A8, A9, A10, A11, A12, A13, A14, A15 };

int pin_samuel_ids [2*num_pins] = {3, 2, 1, 0, 7, 6, 5, 4,
                                     11, 10, 9, 8, 15, 14, 13, 12,
                                     19, 18, 17, 16, 23, 22, 21, 20,
                                     27, 26, 25, 24, 31, 30, 29, 28};

String samuel_to_letters [2*num_pins] = { "A1", "C1", "E1", "G1", "B2", "D2", "F2", "H2",
                                          "A3", "C3", "E3", "G3", "B4", "D4", "F4", "H4",
                                          "A5", "C5", "E5", "G5", "B6", "D6", "F6", "H6",
                                          "A7", "C7", "E7", "G7", "B8", "D8", "F8", "H8" };
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

    update_state(pin_index, state);
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
  Serial.print(pin_samuel_ids[pin_index]);
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

    // If piece was picked up and put back down in the same place
    if (changes[0][0] == changes[1][0]) {

      // Mark as no changes exist
      changes_pos = 0;
    }

    // If a piece was picked up and put down somewhere else
    else if (changes[0][2] == 0 && (changes[1][2] == -1 || changes[1][2] == 1)) {

      int jumped = check_for_jump(changes[0][0], changes[1][0]);

      if (jumped != 0) {
        return;
      }
      
      Serial.print("Move: ");
      Serial.print(changes[0][0]);
      Serial.print(" to ");
      Serial.print(changes[1][0]);
      Serial.println(". No jump.");
      
      send_move_to_fpga(changes[0][0], changes[1][0], 0);
      changes_pos = 0;
    }
    
  } else if (changes_pos == 3) {

    Serial.print("Move: ");
    Serial.print(changes[0][0]);
    Serial.print(" to ");
    Serial.print(changes[1][0]);
    Serial.print(". Jumped: ");
    Serial.println(changes[2][0]);

    send_move_to_fpga(changes[0][0], changes[1][0], changes[2][0]);
    changes_pos = 0;
  }
}

int check_for_jump(int from_pin_samuel, int to_pin_samuel) {

  String from = samuel_to_letters[from_pin_samuel];
  String to = samuel_to_letters[to_pin_samuel];

  int from_col = from.charAt(0) - 64;
  int from_row = from.charAt(1) - 48;

  int to_col = to.charAt(0) - 64;
  int to_row = to.charAt(1) - 48;

  int jumped_row = 0;
  int jumped_col = 0;

  if (to_row == from_row + 2 || to_row == from_row - 2) {
    jumped_row = (from_row + to_row) / 2;
  }

  if (to_col == from_col + 2 || to_col == from_col - 2) {
    jumped_col = (from_col + to_col) / 2;
  }

  if (jumped_row == 0 && jumped_col == 0) {
    return 0;
  }

  return row_col_to_samuel(jumped_row, jumped_col);
}

int row_col_to_samuel(int row, int col) {
  return (row - 1) * 4 + ((col - 1) / 2);
}

// Send a move over clock and data pins. from and to are in samuel coordinates
void send_move_to_fpga(int from, int to, int jump) {
  
  for (int i = 3; i >= 0; i--) {
    //Serial.println(get_number_bit(opcode_send_valid_move, i));
    send_bit(get_number_bit(opcode_send_valid_move, i));
  }

  for (int i = 4; i >= 0; i--) {
    //Serial.println(get_number_bit(to, i));
    send_bit(get_number_bit(jump, i));
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
  delay(1);
  digitalWrite(clock_pin, HIGH);
  delay(1);
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

    send_bit(0);
    send_bit(0);
    send_bit(0);
    send_bit(1);
  }
}
