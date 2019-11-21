# Processor

## Instructions
#### add, sub, and, or, sll, sra
These commands all go into the ALU in the execute state after getting their inputs from the reg file
in the decode/execute stage. The result is passed through the memory stage and into writeback,
where it is written into the regfile.

#### addi
This is the same as the above commands, however the alu input B comes from a sign extended immediate.

#### mul, div
When these commands reach the execute stage, they trigger the mult/div controls and mult/div module.
The mult/div controls module causes the rest of the pipeline to stall, until the multiplication
or division is complete. In the pipeline, the mult and div instructions are replaced by nops in the
X/M register. When the operation is complete, the value is written back into the register file.

#### sw, lw
Both of these commands have a memory address in the A portion of the ALU, which is added to a constant
in alu input B. This address carries through to the memory stage, where the data value is either written
or read into the register file.

#### j, bne, jal, jr, blt
All of these instructions evaluate in the execute stage. Instructions are read following them, and in the
case where the branch is taken, the next two instructions are flushed. bne compares its two values using 
the main ALU, while blt compares its values using a separate adder. jal the next pc writes to register 31
in the writeback stage. This value is bypassed, so any instructions using $r31 right after a jal will
receive the correct value.

#### bex, setx
The bex command evaluates in the execute state, and checks that the value in r30 is equal to zero. If this
is not the case, then the branch is taken. The flushing described above still applies. setx carries its
value through and writes to register 30 in the writeback stage.

## Testing
For testing, I created a test skeleton (called spooky in my test benches) that mux's the inputs to the
regile. This means that if I assert the test signal from my test bench, I can control the inputs to the
regfile. This allowed me to write a check_register task to easily check the values in certain registers
after running mips code through the imem files.

## Regfile
My regfile is implemented quite simply. It has 32 registers, which can be written to using the data_in
and register_in fields. Two values can be read at once using the alu_read_a and alu_read_b pins to
specify the registers to read. $r0 is always equal to zero.

## ALU
My alu is designed as specified. It has an adder inside that is implemented as a carry-lookahead adder.

## multdiv
For my multdiv module, I implemented division as described by the slides, by incrementingly subtracting
values from each location, restoring them if the result was negative, and shifting the result, until the
result of division is determined. For multiplication, I implemented modified booth's algorithm, which
would finish 32 bit multiplication in 16 cycles.

My multdiv was not getting 100 in ag350, so for the processor I used the given multiplier.

## Exceptions
To detect exceptions, I have two modules, one that gets outputs from the alu and one from the multdiv
module.

## Challenges
One big challenge for me at first was testing. It was painful to output every signal from the processor up
to the skeleton and look at the waveform, so I decided to invest time in writing a good testbench format.
This saved me tons of time, and made it easy for me to rerun tests as functional and timing simulations.

I also struggled with bypassing quite a bit. I started with the most basic bypassing, and then gradually
added more cases as I needed. This made my bypassing code quite complicated and difficult to trace. I dealt
with this by looking at all the cases I needed to consider and writing out the logic on paper. I then used
this to reimplement the logic for bypassing.

I also had lots of trouble with timing simulations. I would run a timing simulation, and most tests would
fail. To fix this, I changed lots of muxs into tristate buffers and decoders.

## Known Errors
- Bypassing exception input from memory to execute (writeback to execute works)
  - Did not have time to fix. If I could, I would change how I implemented this and change the instruction
  that caused the exception into an addi instruction that just wrote to register 30. This has the benefit
  of automatially being handled by other bypassing logic.
- Timing Simulations. My processor has some timing issues, and when run in timing simulation mode, quite
a few of my tests do not pass. I verified on a waveform that registers were reading values that had not
yet settled. To fix this, I would change more muxs to tristate buffers, and try to identify my longest
codepath and optimize it.
