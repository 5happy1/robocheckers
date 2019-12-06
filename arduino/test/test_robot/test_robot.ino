
int button_pin = 8;
int x = 0;
int n = 1;

void setup() {
//  Serial.begin(115200);
//  pinMode(LED_BUILTIN, OUTPUT);
//  Serial.println("");
//
//  for (int i = 0; i < 8; i++) {
//    digitalWrite(LED_BUILTIN, HIGH);
//    delay(500);
//    digitalWrite(LED_BUILTIN, LOW);
//    delay(500);
//  }
//  
//  digitalWrite(LED_BUILTIN, HIGH);
//  Serial.println("G0 X100 Y100 Z100 F8000");

 Serial.begin(115200);
 Serial3.begin(115200);
 
 Serial.println("G0 X200 Y50 Z100 F8000");
 Serial3.println("G0 X200 Y50 Z100 F8000");
}

void loop() {

//  String thing = Serial.readStringUntil("\n");
//  if (!thing.equals("")) {
//    Serial3.print(thing);
//  }

}
