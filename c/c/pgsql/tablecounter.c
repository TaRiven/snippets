/*
 * Copyright (c) 2002  Dustin Sallings <dustin@spy.net>
 *
 * $Id: tablecounter.c,v 1.11 2002/03/12 23:04:31 dustin Exp $
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <assert.h>
#include <libpq-fe.h>

#ifdef HAVE_RRD_H
#include <rrd.h>
#endif /* HAVE_RRD_H */

#include "array.h"

#define DBSERVER "db"
#define DBUSER "dustin"
#define DBPASS "blahblah"

#define MAKEDBSPEC3(dbname, table, tscolumn) \
	{ DBSERVER, DBUSER, DBPASS, NULL, dbname, NULL, table, tscolumn}
#define MAKEDBSPEC(dbname, table) MAKEDBSPEC3(dbname, table, "ts")

#define TIGERDB(table) \
	{ "disk", DBUSER, DBPASS, NULL, "tiger", "2345", table, "ts" }

#define INCREMENT 3600

struct checkspec {
	char *server;
	char *user;
	char *pass;
	char *options;
	char *dbname;
	char *port;

	char *table;
	char *ts;
} checkspec;

static PGconn *getConn(struct checkspec query)
{
	PGconn *dbConn=NULL;
	dbConn=PQsetdbLogin(query.server, query.port, query.options, NULL,
		query.dbname, query.user, query.pass);
	if (PQstatus(dbConn) == CONNECTION_BAD) {
		fprintf(stderr, "Error connecting to %s on %s:  %s\n",
			query.dbname, query.server, PQerrorMessage(dbConn));
	}
	return(dbConn);
}

static void cleanConn(PGconn *dbConn) {
	if(dbConn!=NULL) {
		PQfinish(dbConn);
	}
}

void printResults(struct checkspec query, time_t t, int nrows)
{
#ifdef HAVE_RRD_H
	char **args;
	extern int optind;
	int rv=0;
	char buf[8192];

	sprintf(buf, "update %s.%s.rrd %d:%d\n",
		query.dbname, query.table, (int)t, nrows);
	assert(strlen(buf) < sizeof(buf));

	args=split(buf, " ");
	assert(args);

	optind=0;
	rv=rrd_update(listLength(args), args);
	if(rv<0 || rrd_test_error()) {
		fprintf(stderr, "ERROR on %s:  %s\n", buf, rrd_get_error());
		rrd_clear_error();
	}
	freeList(args);
#else /* !HAVE_RRD_H */
	printf("update %s.%s.rrd %d:%d\n",
		query.dbname, query.table, (int)t, nrows);
	fflush(stdout);
#endif /* HAVE_RRD_H */
}

void process(struct checkspec query)
{
	PGconn *dbConn=NULL;
	PGresult *res=NULL;
	char querystr[8192];
	int rv=0;

	dbConn=getConn(query);
	if(dbConn==NULL) {
		goto finished;
	}

	sprintf(querystr, "select count(*) from %s", query.table);

	res=PQexec(dbConn, querystr);
	if(PQresultStatus(res) != PGRES_TUPLES_OK) {
		fprintf(stderr, "Query failed:  %s\n%s\n",
			PQerrorMessage(dbConn), querystr);
		goto finished;
	}

	rv=atoi(PQgetvalue(res, 0, 0));

	printResults(query, time(NULL), rv);

	finished:

	if(res!=NULL) {
		PQclear(res);
	}
	cleanConn(dbConn);

}

void backfill(time_t sincewhen, struct checkspec query)
{
	PGconn *dbConn=NULL;
	PGresult *res=NULL;
	char querystr[8192];
	int count=0, rows=0;
	time_t now=0, ts=0;

	dbConn=getConn(query);
	if(dbConn==NULL) {
		goto finished;
	}

	now=time(NULL);

	sprintf(querystr, "select date_part('epoch', %s) from %s order by %s",
		query.ts, query.table, query.ts);

	res=PQexec(dbConn, querystr);
	if(PQresultStatus(res) != PGRES_TUPLES_OK) {
		fprintf(stderr, "Query failed:  %s\n%s\n",
			PQerrorMessage(dbConn), querystr);
		goto finished;
	}

	rows=PQntuples(res);

	for(count=0; count < rows && sincewhen<now; count++) {
		ts=atoi(PQgetvalue(res, count, 0));

		if(ts>sincewhen) {
			printResults(query, sincewhen, count);
			sincewhen+=INCREMENT;
		}
	}

	finished:

	if(res!=NULL) {
		PQclear(res);
	}
	cleanConn(dbConn);

}

void realmain(time_t backfill_time)
{
	int i=0;
	struct checkspec queries[]={
		MAKEDBSPEC("photo", "photo_logs"),
		MAKEDBSPEC3("music", "music_download_log", "timestamp"),
		MAKEDBSPEC("music", "music_mp3_downloads"),
		MAKEDBSPEC("music", "music_subscribers"),
		MAKEDBSPEC("temperature", "samples"),
		TIGERDB("loaded_files"),
		TIGERDB("type_1"),
		TIGERDB("type_2"),
		TIGERDB("type_3"),
		TIGERDB("type_4"),
		TIGERDB("type_5"),
		TIGERDB("type_6"),
		TIGERDB("type_7"),
		TIGERDB("type_8"),
		TIGERDB("type_9"),
		TIGERDB("type_a"),
		TIGERDB("type_c"),
		TIGERDB("type_h"),
		TIGERDB("type_i"),
		TIGERDB("type_p"),
		TIGERDB("type_r"),
		TIGERDB("type_s"),
		TIGERDB("type_z"),
		MAKEDBSPEC(NULL, NULL),
		};

	if(backfill_time>0) {
		for(i=0; queries[i].table!=NULL; i++) {
			backfill(backfill_time, queries[i]);
		}
	} else {
		for(;;) {
			int started=0, stopped=0, naptime=0;
			started=time(NULL);
			for(i=0; queries[i].table!=NULL; i++) {
				process(queries[i]);
			}
			stopped=time(NULL);
			/* I want to run every hour, so take into consideration the amount
			   of time it took to query all those tables. */
			naptime=INCREMENT - (stopped-started);
			fprintf(stderr, "Sleeping %d seconds\n", naptime);
			sleep(naptime);
		}
	}
}

int main(int argc, char **argv)
{
	time_t backfill_time=0;

	if(argc>1) {
		backfill_time=atoi(argv[1]);
		backfill_time/=3600;
		backfill_time*=3600;
	}

	realmain(backfill_time);
	return(0);
}
