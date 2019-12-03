const int numpins = 16;

int pins[numpins] = {A0, A1, A2, A3, A4, A5, A6, A7, A8,
                     A9, A10, A11, A12, A13, A14, A15
                    };
float pinvals[numpins];

// Wires should be plugged in 0-15 bottom left across rows,
// to the top right

void setup() {
  // put your setup code here, to run once:
  Serial.println("Printing sensor values");
  Serial.begin(9600);
}

void loop() {
  for (int i = 0; i < numpins; i++) {
    pinvals[i] = analogRead(pins[i]) * (5.0 / 1024);
  }

  Serial.println(analogRead(A13));
//  Serial.println("---------------------------------------------");
//  for (int i = 3; i >= 0; i--) {
//    Serial.print(pinvals[4 * i]);
//    Serial.print("\t");
//    Serial.print(pinvals[4 * i + 1]);
//    Serial.print("\t");
//    Serial.print(pinvals[4 * i + 2]);
//    Serial.print("\t");
//    Serial.print(pinvals[4 * i + 3]);
//    Serial.println();
//  }
//  Serial.println("---------------------------------------------");


  Serial.println();
  delay(250);
}
