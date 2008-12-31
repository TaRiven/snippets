/*
 * Copyright (c) 1997  Dustin Sallings
 *
 * $Id: main.c,v 1.2 1998/10/01 16:44:40 dustin Exp $
 */

#include <config.h>
#include <mbkd.h>
#include <readconfig.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/wait.h>

#ifdef HAVE_SYS_TIME_H
#include <sys/time.h>
#endif

#ifdef HAVE_SYS_SELECT_H
#include <sys/select.h>
#endif

#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

struct config conf;

static void
writepid(int pid)
{
	FILE   *f;
	int     r;

	r = checkpidfile(conf.pidfile);

	switch (r) {
	case PID_NOFILE:
		break;
	case PID_STALE:
		puts("Stale PID file found, overriding.");
		break;
	case PID_ACTIVE:
		puts("Active PID file found, exiting...");
		kill(pid, SIGTERM);
		exit(1);
	}

	if (NULL == (f = fopen(conf.pidfile, "w"))) {
		perror(conf.pidfile);
		return;
	}
	fprintf(f, "%d\n", pid);

	fclose(f);
}

static void
detach(void)
{
	int     pid, i;
	char   *tmp;

	pid = fork();

	if (pid > 0) {
		printf("Running on PID %d\n", pid);
		writepid(pid);
		exit(0);
	}
	setsid();

	/* close uneeded file descriptors */

	for (i = 0; i < 256; i++)
		close(i);

	tmp = rcfg_lookup(conf.cf, "etc.working_directory");
	if (tmp == NULL)
		tmp = "/";

	chdir(tmp);
	umask(7);
}

void
process_main()
{
	int     s, len, stat;
	struct sockaddr_in from;
	struct mbk mbk_packet;
	log_msg("Processing...\n");

	s = getservsocket_udp(1099);

	len=1024;

	stat = recvfrom(s, (char *)&mbk_packet, sizeof(mbk_packet),
	    0, (struct sockaddr *) &from, &len);
	if (stat < 0) {
		perror("recvfrom");
	}
	printf("Read %d bytes\n", stat);
	printf("Length:\t%d\nAuth:\t0x%x\nData:\t%s\n", mbk_packet.len,
	       mbk_packet.auth, mbk_packet.data);
}

int
main(int argc, char **argv)
{
	conf.pidfile = "/tmp/mbkd.pid";
	/* detach(); */
	process_main();
	return (0);
}
