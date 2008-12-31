/*
 * Copyright (c) 2000  Dustin Sallings <dustin@spy.net>
 *
 * $Id: main.c,v 1.9 2003/07/29 18:22:33 dustin Exp $
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <assert.h>

#include "proxycgi.h"

/*
 * Parse a url string into a struct url;
 * port is -1, and host and req are NULL if it fails.
 */
struct url
parseurl(char *url)
{
	char   *tmp;
	struct url u;
	int     port;
	struct growstring grow;

	assert(url);

	grow.size = 1024 * sizeof(char);
	grow.string = calloc(1, grow.size);
	assert(grow.string);

	u.host = NULL;
	u.req = NULL;
	u.port = -1;

	/* We only do http urls */
	if (strncmp(url, "http://", 7) != 0) {
		return(u);
	}

	/* Host is the first thing, after http:// */
	u.host = strdup(url + 7);

	/*
	 * OK, request comes along eventually, so let's mark it as host, and
	 * go from there.  Look for a :, /, or NULL to let us know we're done
	 * with host.
	 */
	u.req = u.host;
	while (*u.req && *u.req != ':' && *u.req != '%' && *u.req != '/')
		u.req++;

	/*
	 * Let's see which one we got.
	 */
	switch (*u.req) {
	case NULL:		/* format http://host.domain.com */
		u.req = strdup("/");
		port = 80;
		break;
	case ':':		/* format http://host.domain:port/ */
		port = atoi(u.req + 1);
		assert(port);
		*u.req = NULL;
		u.req++;
		while (*u.req && *u.req != '/')
			u.req++;
		u.req = *u.req ? strdup(u.req) : "/";
		break;
	case '%':		/* Check for %3A */
		if(strlen(u.req)>3 && u.req[1]=='3' && tolower(u.req[2])=='a') {
			/* Same as colon, except longer */
			port = atoi(u.req + 3);
			*u.req=NULL;
			u.req+=3;
			while (*u.req && *u.req != '/')
				u.req++;
			u.req = *u.req ? strdup(u.req) : "/";
		}
		break;
	case '/':		/* format http://host.domain.com/ */
		port = 80;
		tmp = u.req;
		u.req = strdup(u.req);
		*tmp = NULL;
		break;
	}

	str_append(&grow, "GET ");
	str_append(&grow, u.req);
	str_append(&grow,  " HTTP/1.0\r\n");
	str_append(&grow,  "Host:  ");
	str_append(&grow,  u.host);
	str_append(&grow,  "\r\n");

	/* This ends the GET request */
	str_append(&grow,  "\r\n");

	u.httpreq=grow.string;

	u.port = port;
	return (u);
}

struct ProxyStruct parseuri(char *uri)
{
	struct ProxyStruct ret;
	char **atmp;
	char tmpfiletmp[64];
	struct growstring grow;
	int i;

	/* Verify we got something */
	assert(uri);

	/* Initialize the growstring */
	grow.size=1024*sizeof(char);
	grow.string=calloc(sizeof(char), grow.size);

	/* Copy the uri */
	ret.request_uri=strdup(uri);

	/* we prepend each part with a / in the for loop */
	str_append(&grow, "http:/");
	atmp=split('/', uri);
	for(i=3; atmp[i]!=NULL; i++) {
		str_append(&grow, "/");
		str_append(&grow, atmp[i]);
	}

	/* Get the URL stuff */
	ret.request_url=strdup(grow.string);
	ret.url=parseurl(ret.request_url);

	/* Get the file */
	grow.string[0]=0x00;
	str_append(&grow, GETENV("DOCUMENT_ROOT"));
	str_append(&grow, "/");
	str_append(&grow, ret.request_uri);

	ret.file=strdup(grow.string);

	sprintf(tmpfiletmp, ".tmp.%d", getpid());
	str_append(&grow, tmpfiletmp);
	ret.tmpfile=grow.string;

	freeptrlist(atmp);

	return(ret);
}

int check_auth(struct ProxyStruct p)
{
	int rv=FALSE;
	char linebuf[80];
	struct growstring grow;
	FILE *f=NULL;

	/* Initialize a growstring */
	grow.size=80*sizeof(char);
	grow.string=calloc(sizeof(char), grow.size);

	/* Look for ok=host:port */
	str_append(&grow, "ok=");
	str_append(&grow, p.url.host);
	sprintf(linebuf, ":%d", p.url.port);
	str_append(&grow, linebuf);

#ifdef UGLY_DEBUG
	fprintf(stderr, "Looking in %s for %s\n", CONFFILE, grow.string);
#endif

	/* Open the config file and try to find a matching entry */
	f=fopen(CONFFILE, "r");
	/* If we opened the file, all's well, else rv will remain false */
	if(f!=NULL) {
		/* For each line in the file (as long as we haven't found it */
		while(rv==FALSE && (fgets(linebuf, sizeof(linebuf), f)!=NULL) ) {
			if(strncmp(grow.string, linebuf, strlen(grow.string))==0) {
				/* Found it! */
				rv=TRUE;
			}
		}
		fclose(f);
	} else {
		perror("proxycgi config error:  " CONFFILE);
	}

	return(rv);
}

int start_request(struct ProxyStruct proxystruct)
{
	int s, size;

	s=getclientsocket(proxystruct.url.host, proxystruct.url.port);
	assert(s>0);

	size=send(s, proxystruct.url.httpreq, strlen(proxystruct.url.httpreq),0);
	assert(size=strlen(proxystruct.url.httpreq));

	return(s);
}

/* This will destroy the input as it replaces */
int parse_headers(char *buf, int *size)
{
	int s=0, index=0, done;
	char *p, *left, *end;
	char outbuf[8192];
	struct growstring grow;

	/* Find the end of the headers string. */
	index=4;
	end=strstr(buf, "\r\n\r\n");
	/* This is in the protocol spec, but I'm not taking chances */
	if(end==NULL) {
		index=2;
		/* Try LFLF */
		end=strstr(buf, "\n\n");
		if(end==NULL) {
			/* Try CRCR */
			end=strstr(buf, "\r\r");
			if(end==NULL) {
				/* We didn't find the end, it's just not here */
				return(-1);
			}
		}
	}
	*end=0x00;
	end+=index;
	s=*size-((int)end-(int)buf);

	grow.size=1024*sizeof(char);
	grow.string=calloc(sizeof(char), grow.size);

	left=buf;
	p=strchr(buf, '\n');
	done=0;
	while(!done) {
		if(p) {
			*p=NULL;
			p++;
		}
		kw(left);

		/* Find the stuff we want */

		if(strncasecmp(left, "HTTP/1.1", 8)==0) {
			char *ptmp;
			/* We need to output this directly,
			 * but not let it appear in the file.
			 * ...well, sometimes.
			 */
			/*
			write(1, left, strlen(left));
			write(1, "\r\n", 2);
			*/
			left=strchr(left, ' ');
			assert(left);
			left++;
			ptmp=strchr(left, ' ');
			assert(ptmp);
			*ptmp=NULL;
			str_append(&grow, "Status:  ");
			str_append(&grow, left);
			str_append(&grow, "\r\n");
		}

		#define startsWith(haystack, needle) \
			(strncasecmp(haystack, needle, strlen(needle)) == 0)

		#define appendIfMatch(haystack, needle) \
			if(startsWith(haystack, needle)) { \
				str_append(&grow, left); \
				str_append(&grow, "\r\n"); \
			}

		appendIfMatch(left, "Content-Type");

		appendIfMatch(left, "Content-Length");

		appendIfMatch(left, "Content-Encoding");

		#undef startsWith
		#undef appendIfMatch

		/* Find the next left */
		for(; p && *p && isspace(*p); p++);
		if(p && *p) {
			left=p;
			p=strchr(p, '\n');
		} else {
			/* Looks like we're done, do one more iteration */
			p=NULL;
			done=1;
		}
	}
	/* a new line to end the thing */
	str_append(&grow, "\r\n");

	/* Make sure we have enough room */
	assert(sizeof(outbuf) > s);

	/* Copy into our tmp buffer */
	memcpy(outbuf, grow.string, strlen(grow.string));
	memcpy(outbuf+strlen(grow.string), buf+(*size-s), s);

	s+=strlen(grow.string);
	*size=s;

	/* Copy it back */
	memcpy(buf, outbuf, s);

	/* free the grow string */
	free(grow.string);

	return(1);
}

void
do_error(int status, char *type, char *msg)
{
	printf("Status: %d\r\nContent-type: %s\r\n\r\n%s\r\n", status, type, msg);
}

void
pre_check()
{
	int cont=TRUE;

	/* Make sure the required environment variables are there */
	if(getenv("REQUEST_URI")==NULL || getenv("DOCUMENT_ROOT")==NULL) {
		fprintf(stderr,
			"Required CGI variables not present.  Is this a CGI?\n"
			);
		fprintf(stderr, "The following CGI variables are required:\n"
			"\tREQUEST_URI\n"
			"\tDOCUMENT_ROOT\n\n"
			);
		cont=FALSE;
	}

	/* Make sure we can read the config file */
	if(access(CONFFILE, R_OK)<0) {
		fprintf(stderr,
			"Could not read config file:  %s\n", CONFFILE);
		perror("reason");
		fprintf(stderr,
			"\nThe config file should contain lines that appear as follows:\n"
			"\n# Allow to proxy to server:80\n"
			"ok=server:80\n\n"
			"Please note that the port number *is* required, even if it's 80\n"
			);
		fprintf(stderr, "\n");
		cont=FALSE;
	}

	if(cont==FALSE) {
		fprintf(stderr, "One or more pre-checks failed, exiting.\n");
		exit(-1);
	}
}

int main(int argc, char **argv)
{
	struct ProxyStruct proxystruct;
	int s, f, size, rv, parsed_headers=0;
	char recv_buf[8192];

	/* Make sure stuff sane */
	pre_check();

	proxystruct=parseuri(GETENV("REQUEST_URI"));

#ifdef UGLY_DEBUG
	fprintf(stderr, "URL:  %s\nURI:  %s\nFile:  %s\n",
		proxystruct.request_url, proxystruct.request_uri, proxystruct.file);
	fprintf(stderr, "URL Structure:\n\tHost:  %s\n\tPort:  %d\n\tURI:  %s\n",
		proxystruct.url.host, proxystruct.url.port, proxystruct.url.req);
	fprintf(stderr, proxystruct.url.httpreq);
#endif /* UGLY_DEBUG */

	/* Make sure we allow access to this host and port (and what not) */
	if(check_auth(proxystruct)==FALSE) {
		do_error(403, "text/plain", "You are not authorized to do get this.");
	} else {
		ensurepath(proxystruct.file);
		f=open(proxystruct.tmpfile, O_WRONLY|O_CREAT|O_EXCL, 0644);
		if(f<0) {
			perror(proxystruct.tmpfile);
		}

		s=start_request(proxystruct);

		while( (size=recv(s, recv_buf, sizeof(recv_buf), 0)) > 0) {
			if(parsed_headers==0) {
				parsed_headers=parse_headers(recv_buf, &size);
			}

			rv=write(1, recv_buf, size);
			assert(rv==size);

			if(f>=0) {
				rv=write(f, recv_buf, size);
				assert(rv==size);
			}
		}

		/* Save it */
		if(rename(proxystruct.tmpfile, proxystruct.file)<0) {
			perror(proxystruct.file);
		}
	}

	return(0);
}
