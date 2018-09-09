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
//  Socket server that receives a single value from a client such as 6,
//   and returns a list of N Fibinocci numbers such as "1 1 2 3 5 8"
//

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <string.h>

#define PORT 		0x1234
#define FIBSIZE 	8192

int main()
{
        char     fib[FIBSIZE];  /* used for incomming fib name, and
					outgoing data */
	int 	 sd, sd_current, cc, fromlen, tolen, fibmax, n[1000], i;
	int 	 addrlen;
	struct   sockaddr_in sin;
	struct   sockaddr_in pin;
 
	printf("SERVER: get an internet domain socket\n");
	if ((sd = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
		perror("socket");
		exit(1);
	}

	printf("SERVER: complete the socket structure\n");
	memset(&sin, 0, sizeof(sin));
	sin.sin_family = AF_INET;
	sin.sin_addr.s_addr = INADDR_ANY;
	sin.sin_port = htons(PORT);

	printf("SERVER: bind the socket to the port number\n");
	if (bind(sd, (struct sockaddr *) &sin, sizeof(sin)) == -1) {
		perror("bind");
		exit(1);
	}

	printf("SERVER: show that we are willing to listen\n");
	if (listen(sd, 5) == -1) {
		perror("listen");
		exit(1);
	}
	printf("SERVER: wait for a client to talk to us\n");
        addrlen = sizeof(pin); 
	if ((sd_current = accept(sd, (struct sockaddr *)  &pin, &addrlen)) == -1) {
		perror("accept");
		exit(1);
	}

//	printf("SERVER: >> Hi there, from ip address '%s'\n",inet_ntoa(pin.sin_addr));
//	printf("SERVER: >> Coming from port %d\n",ntohs(pin.sin_port));

	printf("SERVER: get a message from the client\n");
	if (recv(sd_current, fib, sizeof(fib), 0) == -1) {
		perror("recv");
		exit(1);
	}

        printf("SERVER: Received message '%s'\n", fib);
	if (sscanf(fib, "%d", &fibmax) != 1) {
	  printf("SERVER: Unable to get fibmax decimal value from '%s'\n", fib);
	  exit(1);
	}
	
	strcpy(fib,"1");
	n[0] = 1;
	n[1] = 1;
	for (i=1; i<fibmax; i++) {
	  sprintf(fib, "%s %d", fib, n[i]);
	  n[i+1] = n[i+0] + n[i-1];
	}

        printf("SERVER: Response message '%s'\n", fib);
      /* strcat (fib," DUDE");
       */
	 printf("SERVER: acknowledge the message, reply w/ the file names\n");
	if (send(sd_current, fib, strlen(fib), 0) == -1) {
		perror("send");
		exit(1);
	}

        printf("SERVER: close up both sockets\n");
	close(sd_current); close(sd);
        
        printf("SERVER: give client a chance to properly shutdown\n");
        sleep(1);
	printf("SERVER: bye!\n");
}
