//-----------------------------------------------------------------------------
// This code example can be shared freely as long as you keep
// this notice and give us credit. In the event of publication,
// the following notice is applicable:
//
// (C) COPYRIGHT 2011 Chris Spear.  All rights reserved
//
// It is derived from http://www.pcs.cnu.edu/~dgame/sockets/socket.html,
// which is derived from the RPC Programming Nutshell text.
// The entire notice above must be reproduced on all authorized copies.
//-----------------------------------------------------------------------------

This is an example of a client / server combined with SystemVerilog
Direct Programming Interface.

It is derived from http://www.pcs.cnu.edu/~dgame/sockets/socket.html,
which is derived from the RPC Programming Nutshell text.

The server, in fib_server.c, accepts a string with a number N such as
"5". It then generates a string with the first N numbers in the
Fibonocci sequence such as "1 1 2 3 5".

The client, in client.c, accepts a count, N, and an optional host name. It
passes N over to the server, and receives back a string with N values,
separated by spaces.

This same example runs in SystemVerilog. The program client.sv calls
the C routine client_dpi, passing N and the optional hostname. This
then passes a string with N over to the server and receives back a the
space-separated list of values. These values are parsed and returned
to SV in an array of ints.

Not much error checking is done.

