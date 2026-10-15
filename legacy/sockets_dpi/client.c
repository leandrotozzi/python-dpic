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
//  Client code to send a number to a server and receive back a list of N Fibinocci numbers
//  Usage:
//	client N <name>
//  N = number of values, default 5
//  name = server name
//

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <string.h>

#define PORT        0x1234
             /* REPLACE with your server machine name*/
#define HOST        "localhost"
#define DIRSIZE     8192

int main(argc, argv)
     int argc; char **argv;
{
        char hostname[100];
	char    dir[DIRSIZE];
	int	sd, i;
	struct sockaddr_in sin;
	struct sockaddr_in pin;
	struct hostent *hp;

	for (i=0; i<argc; i++)
	  printf("CLIENT: argv[%d]='%s'\n", i, argv[i]);

        strcpy(hostname,HOST);
        if (argc>2)
            { strcpy(hostname,argv[2]); }

	if (argc < 2) {
	  printf("CLIENT: Hey - you forgot to specify a number\n\tRun with:\n\t\t%s 5\n", argv[1]);
	  exit(1);
	}

	printf("CLIENT: go find out about the desired host machine\n");
	if ((hp = gethostbyname(hostname)) == 0) {
		perror("gethostbyname");
		exit(1);
	}

	printf("CLIENT: fill in the socket structure with host information\n");
	memset(&pin, 0, sizeof(pin));
	pin.sin_family = AF_INET;
	pin.sin_addr.s_addr = ((struct in_addr *)(hp->h_addr))->s_addr;
	pin.sin_port = htons(PORT);

	printf("CLIENT: grab an Internet domain socket\n");
	if ((sd = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
		perror("socket");
		exit(1);
	}

	printf("CLIENT: connect to PORT on HOST\n");
	if (connect(sd,(struct sockaddr *)  &pin, sizeof(pin)) == -1) {
		perror("connect");
		exit(1);
	}

	printf("CLIENT: send a message to the server PORT on machine HOST\n");
	if (send(sd, argv[1], strlen(argv[1]), 0) == -1) {
		perror("send");
		exit(1);
	}

        printf("CLIENT: wait for a message to come back from the server\n");
        if (recv(sd, dir, DIRSIZE, 0) == -1) {
                perror("recv");
                exit(1);
        }

        printf("CLIENT: spew-out the results and bail out of here!\n");
        printf("CLIENT: '%s'\n", dir);

	int val[1000], vidx;
	vidx = 0;
	val[vidx] = 0;
	i = 0;
 	while (dir[i]) { 
	  while (isdigit(dir[i])) {
	    val[vidx] = val[vidx] * 10 + dir[i++] - '0';
	  }
	  printf("CLIENT: val[%d]=%d\n", vidx++, val[vidx]);
	  val[vidx] = 0;
	  i++;
	  }

	close(sd);
        printf("CLIENT: bye!\n");

	return 0;
}
