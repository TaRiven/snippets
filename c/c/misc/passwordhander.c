/*
 * Copyright (c) 2002  Dustin Sallings <dustin@spy.net>
 *
 * $Id: passwordhander.c,v 1.2 2002/07/09 00:19:23 dustin Exp $
 *
 * Read a file and copy it to a new file descriptor into a pipe so's that a
 * subprocess can read it on a specific file descriptor.  The subprocess
 * will be created by shifting the argv over two positions.
 */

#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <signal.h>
#include <assert.h>

static void
sigChildHandler(int sig)
{
	int status=0;
	int myexitcode=0;
	pid_t p=0;

	p=wait(&status);

	if(p>=0) {
		myexitcode=WEXITSTATUS(status);
	}

	exit(myexitcode);
}

static void
copyFile(int src, int dest)
{
	char buf[4096];
	size_t bytesW=0, bytesR;

	while(bytesR>=0) {
		bytesR=read(src, &buf, sizeof(buf));
		if(bytesR>0) {
			bytesW=write(dest, buf, bytesR);
			assert(bytesW == bytesR);
		} else if(bytesR<0) {
			perror("read");
		}
	}
}

static void
usage(char *name)
{
	fprintf(stderr, "Usage:  %s filename command [options]\n", name);
	fprintf(stderr, "  The contents of filename will be passed to command "
					"on file descriptor 4.\n");
	exit(1);
}

int main(int argc, char **argv)
{
	pid_t p=0;
	int pipeparts[2];
	int readFd=-1;

	/* Make sure there are enough arguments */
	if(argc<=2) {
		usage(argv[0]);
	}

	/* Setup signal handlers */
	signal(SIGCHLD, sigChildHandler);

	/* Open the file */
	readFd=open(argv[1], O_RDONLY);
	if(readFd<0) {
		perror(argv[1]);
		exit(1);
	}

	/* create the pipe */
	if(pipe(pipeparts) < 0) {
		perror("pipe");
		exit(1);
	}

	/*
	fprintf(stderr, "Read will be available on fd %d\n", pipeparts[0]);
	*/

	/* Fork and do the stuff */
	p=fork();
	switch(p) {
		case -1:
			perror("fork");
			exit(1);
			break;
		case 0:
			/* Close the write end */
			close(pipeparts[1]);
			/* Call the real program */
			execvp(argv[2], argv+2);
			break;
		default:
			/* Close the read end */
			close(pipeparts[0]);
			copyFile(readFd, pipeparts[1]);
			/* Wait for a signal */
			pause();
			break;
	}
}