int pin = A0;
int state = 0;
int next_state = 0;
unsigned long time_difference_started = 0;

float threshold_upper = 3;
float threshold_lower = 2;

// If state is changed for this amount of time, the state is officially changed
float time_for_new_state = 500;

void setup() {
  Serial.begin(9600);
  Serial.print("Starting state: ");
  Serial.println(state);
}

void loop() {

  int new_state = state_of_pin(pin);

  // If new state is different and the change is not yet recorded in next_state, set
  // next_state and start a timer
  if (new_state != state && new_state != next_state) {
    next_state = new_state;
    time_difference_started = millis();
  }

  if (next_state != state && millis() - time_difference_started > time_for_new_state) {
    state = next_state;
    Serial.print("State changed, now is ");
    Serial.println(state);
  }

}

int state_of_pin(int pin) {
  
  float voltage = analogRead(pin) * (5.0 / 1024);

  if (voltage < threshold_lower) {
    return -1;
  } else if (voltage > threshold_upper) {
    return 1;
  } else {
    return 0;
  }
}
