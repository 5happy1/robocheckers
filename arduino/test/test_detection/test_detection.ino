const int num_pins = 16;

// Pin information
int pins[num_pins] = {A0, A1, A2, A3, A4, A5, A6, A7,
                     A8, A9, A10, A11, A12, A13, A14, A15 };
float upper_thresholds[num_pins];
float lower_thresholds[num_pins];
//
//const A1 = 0;
//const A3 = 
//const A5 = 
//const A7 = 

// State information
int states[num_pins];
int next_states[num_pins];
unsigned long times_differences_started[num_pins];

// Constants
float upper_threshold_default = 3;
float lower_threshold_default = 2;

// If state is changed for this amount of time, the state is officially changed
float time_for_new_state = 400;

void setup() {

  // Initialize variables
  for(int i = 0; i < num_pins; i++) {

    // Thresholds
    upper_thresholds[i] = upper_threshold_default;
    lower_thresholds[i] = lower_threshold_default;

    // State information
    states[i] = 0;
    next_states[i] = 0;
    times_differences_started[i] = 0;
  }
  

  // Initialize Serial
  Serial.begin(9600);
}

void loop() {

  for (int pin_index = 0; pin_index < num_pins; pin_index++) {

    int new_state = state_of_pin(pin_index);
  
    // If new state is different and the change is not yet recorded in next_state, set
    // next_state and start a timer
    if (new_state != states[pin_index] && new_state != next_states[pin_index]) {
      next_states[pin_index] = new_state;
      times_differences_started[pin_index] = millis();
    }
  
    if (next_states[pin_index] != states[pin_index] &&
        millis() - times_differences_started[pin_index] > time_for_new_state) {
      states[pin_index] = next_states[pin_index];
      Serial.print("Pin ");
      Serial.print(pin_index);
      Serial.print(" state changed, to ");
      Serial.println(states[pin_index]);
    }
  }

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
