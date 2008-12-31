/*
 * Copyright (c) 1998  Dustin Sallings
 *
 * $Id: splat.h,v 1.11 2000/10/03 10:07:38 dustin Exp $
 */

#ifndef SPLAT_H
#define SPLAT_H

/* Debug stuff */
#ifndef PDEBUG
#define PDEBUG 1
#endif

#if (PDEBUG>0)
#ifndef _ndebug
#define _ndebug(a, b) if(_debug >= a ) printf b;
#endif
#endif

/* In case it didn't make it */
#ifndef _ndebug
#define _ndebug(a, b)
#endif

#define REQ_LEN 8192

/* Socket options */
#define DO_NAGLE 1
#define NO_BLOCKING 2

#ifdef USE_SSLEAY
#include <rsa.h>
#include <crypto.h>
#include <x509.h>
#include <pem.h>
#include <ssl.h>
#include <err.h>


#define CHK_NULL(x) if ((x)==NULL) {printf("Got NULL\n"); exit (1);}
#define CHK_ERR(err,s) if ((err)==-1) { perror(s); exit(1); }
#define CHK_SSL(err) if ((err)==-1) { ERR_print_errors_fp(stderr); exit(2); }
#endif /* USE_SSLEAY */

/*
 * Host return thing
 */
struct host_ret {
	int	s;
#ifdef USE_SSLEAY
	SSL    *ssl;
	SSL_CTX *ctx;
#endif /* USE_SSLEAY */
};

/*
 * URL request holder.
 */
struct url {
	char   *host;
	int     port;
	char   *req;
	char   *httpreq;
	int     ssl;
};

/*
 * Status return.
 */
struct status {
	int     status;
	int     bytesread;
	char   *message;
};

struct growstring {
	size_t size;
	char *string;
};

struct http_status {
	int status;
	char *string;
};

struct host_ret getclientsocket(struct url u, int flags);
void str_append(struct growstring *grower, char *string);
struct url parseurl(char *url);


#endif
