# PWMTEST

This program tests the PWM analog output.  This test at the moment
only works when using the standard v5a ROM because the extended ROM is
expected to forwards the audio signal to the PWM output.

The test simply allows to change the analog level in range 0 to 63.
The corresponding voltage can be measured on the PWM header on boards
that feature a PWM header, or on the XIN3 pin on the extension header
on the other boards.

