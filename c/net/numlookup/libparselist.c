/*
 * Copyright (c) 1997  Dustin Sallings
 *
 * $Id: libparselist.c,v 1.20 1999/06/07 23:37:40 dustin Exp $
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdarg.h>
#include <string.h>
#include <strings.h>
#include <assert.h>
#include <sys/types.h>
#include <time.h>

#include "mymalloc.h"
#include "hash.h"
#include "parselist.h"

/* Initialize a config structure */
static struct config_t 
initConfig(void)
{
	struct config_t config;
	int i;

	for(i=0; i<=IP_SIZE; i++) {
		config.hash[i] = hash_init(HASHSIZE);

		/* Canned masks */
		if(i==0) {
			config.masks[0]=0;
		} else {
			config.masks[i]=(0xffffffff << (IP_SIZE-i));
		}
	}

	return (config);
}

/* This code is kinda duplicated from below, but we can deal with that */
static int 
parseIP(const char *ip)
{
	int     a[4], n;
	unsigned int ret;

	n=sscanf(ip, "%d.%d.%d.%d", &a[0], &a[1], &a[2], &a[3]);
	if(n!=4)
		return(0);
	ret = (a[0] << 24) | (a[1] << 16) | (a[2] << 8) | a[3];
	return (ret);
}

/*
 * I usually call this routine ``killwhitey,'' but I stole it from
 * Nathan, so I'll keep the name.
 */
static char *
getCleanLine(char *data, int size, FILE * infile)
{
	char *first_char, *comment, *last_char;

	if (fgets(data, size, infile) == NULL)
		return(NULL);

	comment = strchr(data, '#');

	if (comment != NULL)
		comment[0]=0x00;

	first_char = data + strspn(data, " \t");

	last_char = first_char + strlen(first_char) - 1;
	while (last_char >= first_char && index(" \t\n", *last_char)) {
		*last_char = 0x00;
		last_char--;
	}
	return(strcpy(data, first_char));
}

/* Read the config */
static struct config_t 
readconfig(char *config_file)
{
	char    line[LINELEN];
	struct config_t config;
	FILE   *f;

	/* allocate a new config */
	config = initConfig();

	f = fopen(config_file, "r");
	if (f == NULL) {
		perror(config_file);
		return (config);
	}
	/* We've got a macro for appending to the address list */

	while (getCleanLine(line, LINELEN - 1, f)) {
		int     a[4], mask, n, addr;
		char    data[LINELEN];

		if(strlen(line)==0) {
			/* skip if the line is blank */
			continue;
		}

		n = sscanf(line, "%d.%d.%d.%d/%d:%s",
			&a[0], &a[1], &a[2], &a[3], &mask, data);
		if (n != 6) {
			_log("Error in config file [%s]\n", line);
			continue;
		}

		if (mask < 0 || mask > IP_SIZE) {
			_log("ERROR, netmask is invalid:  %s\n", line);
			continue;
		}

		/* The IP address */
		addr = (a[0] << 24) | (a[1] << 16) | (a[2] << 8) | a[3];

		/* apply the netmask to the address */
		addr&=config.masks[mask];

		/* store it in our hash */
		if(hash_store(config.hash[mask], addr, data)==0) {
			_log("Error storing entry:  %d/%d (%s)", addr, mask, line);
			continue;
		}
	}
	(void)fclose(f);
	return (config);
}

static void 
destroyConfig(struct config_t config)
{
	int     i;

	for (i = 0; i <= IP_SIZE; i++) {
		if (config.hash[i]) {
			hash_destroy(config.hash[i]);
		}
	}
}

static char   *
search(struct config_t config, unsigned int ip)
{
	int     i, addr, which;
	struct	hash_container *h;

	/* We have an array of integer hashes of all of our known networks.  The
	 * array offset is the netmask (CIDR), so lookups are quick and accurate */
	for (i = IP_SIZE; i >= 0; i--) {
		addr=ip&config.masks[i];
		h=hash_find(config.hash[i], addr);
		if(h) {
			if(h->index>1) {
				/* We do this if we have more than one value */
				which=(ip%h->index);
				_log("Multiple values matched, returning %d\n", which);
			} else {
				/* We'll special case a single result for speed */
				which=0;
			}

			return(h->value[which]);
		}
	}
	/* Return an empty string if nothing found.
	 * This implies misconfiguration */
	return (DEFAULT_OUTPUT);
}

int 
main(int argc, char **argv)
{
	struct config_t config;
	char   *val, *tmp, *config_file;
	char    buf[LINELEN];
	time_t	t;

	if(argc<2) {
		config_file=CONFIGFILE;
	} else {
		config_file=argv[1];
	}

	config = readconfig(config_file);
	t=time(0);

	_log("Beginning main lib loop at %d\n", (int)t);

	while ( (time(0)-t) < LIFETIME ) {
		tmp = fgets(buf, LINELEN - 1, stdin);
		if (tmp == NULL) {
			_log("Received EOF, exiting...\n");
			exit(0);
		}
		buf[strlen(buf) - 1] = 0x00;
		val = search(config, parseIP(buf));
		if (val) {
			_log("Received [%s] Sent [%s]", buf, val);
			puts(val);
			fflush(stdout);
		} else {
			_log("AHH!!!!  Nothing found for %s", buf);
			puts(DEFAULT_OUTPUT);
			fflush(stdout);
		}
	}

	_log("Ending main lib loop at %d\n", (int)time(0));

	destroyConfig(config);
	closelog();

#ifdef MYMALLOC
	_mdebug_dump();
#endif

	return(0);
}
