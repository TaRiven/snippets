/*
 * Copyright (c) 1999  Dustin Sallings
 *
 * $Id: executor.c,v 1.2 1999/10/06 18:06:40 dustin Exp $
 *
 * This program is used to execute commands found in another directory.
 * Useful for hiding shell scripts.
 */

#include <stdio.h>
#include <unistd.h>
#include <assert.h>

#ifndef CMD_DIRECTORY
#define CMD_DIRECTORY "/usr/local/secbin/"
#endif

int main(int argc, char **argv)
{
	char path[8192];
	char cmd[8192];
	int i=0,j=0;

	/* Get the initial directory */
	strcpy(path, CMD_DIRECTORY);

	/* make sure the arguments are set and all that */
	assert(argv[0]);
	assert(strlen(argv[0])>0);

	/* Find the basename */
	for(i=strlen(argv[0]); i>0 && argv[0][i] != '/'; i--);

	/* Copy the basename into cmd */
	for(j=0; i<strlen(argv[0]); i++) {
		assert(j<8190);
		cmd[j++]=argv[0][i];
	}
	cmd[j]=0x00;

	/* Make sure we're not about to overflow a buffer */
	assert(strlen(path) + strlen(cmd) < 8190);
	/* concatenate */
	strcat(path, cmd);

	/* run the program */
	execvp(path, argv);
}
