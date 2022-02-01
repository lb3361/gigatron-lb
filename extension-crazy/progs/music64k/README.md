# Music64k

This is a version of at67's Music64k_ROMv5a program modified to
compile outside the Contrib directory. This program makes nice sine
waves that can be used to test 6 bits audio with pwm.

It can also be tested inside gtemuAT67 by switching on or off the 6
bits option in the audio dialog. When used from gtemuAT67, the wave
display shows the 6 bits because they're taken from xout after at67's
rom patch. When used from the Gigatron512k, the wave display still
shows the 4 bits, but the PWM output should give 6 bits.


