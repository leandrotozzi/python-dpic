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
//

program automatic top;
   parameter int VALSIZE = 10;

   import "DPI-C" function void client_dpi(input int count,
					   input string hostname,
					   output int vals[VALSIZE]);

      int vals[VALSIZE];

      initial begin
	 client_dpi(5, "localhost", vals);
	 $display("V: vals=%p", vals);
      end
endprogram : top
