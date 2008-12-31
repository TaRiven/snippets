/*
 * Copyright (c) 1997 Dustin Sallings
 *
 * $Id: sockets.c,v 1.3 1998/10/01 17:04:51 dustin Exp $
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

#include <mbkd.h>
#include <nettools.h>
#include <readconfig.h>

extern struct config conf;

char   *
getHostName(unsigned int addr)
{
	struct hostent *h;
	char   *name;

	h = gethostbyaddr((void *) &addr, sizeof(unsigned int), AF_INET);
	if (h == NULL)
		name = nmc_intToDQ(ntohl(addr));
	else
		name = h->h_name;

	return (name);
}

void
logConnect(struct sockaddr_in fsin)
{
	char   *ip_addr, *hostname;

	if (rcfg_lookupInt(conf.cf, "log.hostnames") == 1)
		hostname = getHostName(fsin.sin_addr.s_addr);
	else
		hostname = nmc_intToDQ(ntohl(fsin.sin_addr.s_addr));

	ip_addr = nmc_intToDQ(ntohl(fsin.sin_addr.s_addr));

	log_msg("connect from %s (%s)", hostname, ip_addr);

	_ndebug(2, ("connect from %s (%s)\n", hostname, ip_addr));
}

int
getservsocket_udp(int port)
{
	int     reuse = 1, s;
	struct sockaddr_in sin;

	signal(SIGPIPE, SIG_IGN);

	if ((s = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
		perror("server: socket");
		exit(1);
	}
	memset((char *) &sin, 0x00, sizeof(sin));
	sin.sin_family = AF_INET;
	sin.sin_port = htons(port);
	sin.sin_addr.s_addr = htonl(INADDR_ANY);

	if (bind(s, (struct sockaddr *) &sin, sizeof(sin)) < 0) {
		perror("server: bind");
		exit(1);
	}
	return (s);
}
