# MEMTEST

This program test the memory banking features and in particular the extended banking.

-  The first page tests that memory banking is correctly reset to good default values. No display means ok.
-  The second page tests extended memory banking which permits to read from a bank and write to another at the same time.
-  The last set of tests writes patterns in the memory using either the classic memory banking scheme or the extended memory banking scheme, then tests that it can read the correct patterns using either the classic memory banking scheme or the extended memory banking scheme. No error message means that it works.
