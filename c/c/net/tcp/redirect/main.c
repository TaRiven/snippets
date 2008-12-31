/*
 * Copyright (c) 1998  Dustin Sallings
 *
 * $Id: main.c,v 1.11 1998/01/10 03:33:41 dustin Exp $
 */

#include <config.h>
#include <redirect.h>
#include <readconfig.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <assert.h>

struct confType *cf;
int _debug;

static void resettraps(void);

static RETSIGTYPE serv_sigint(int sig)
{
    char *pidfile;
    _ndebug(0, ("Exit type signal caught, shutting down...\n"));

    pidfile=rcfg_lookup(cf, "etc.pidfile");
    if(pidfile==NULL)
        pidfile=DEFPIDFILE;

    unlink(pidfile);
    exit(0);
}

static RETSIGTYPE serv_cluster_alrm(int sig)
{
    _ndebug(2, ("Caught alrm on connect attempt\n"));
    resettraps();
    return;
}

static void resettraps(void)
{
    signal(SIGINT, serv_sigint);
    signal(SIGQUIT, serv_sigint);
    signal(SIGTERM, serv_sigint);
    signal(SIGHUP, serv_sigint);
    signal(SIGALRM, serv_cluster_alrm);

}

static int checkpidfile(char *filename)
{
    int pid, ret;
    FILE *f;

    if( (f=fopen(filename, "r")) == NULL)
    {
        return(PID_NOFILE);
    }
    else
    {
        fscanf(f, "%d", &pid);

        _ndebug(2, ("Checking pid %d for life\n", pid));

        if( kill(pid, 0) ==0)
        {
           ret=PID_ACTIVE;
        }
        else
        {
           ret=PID_STALE;
        }
    }

    return(ret);
}

static void writepid(int pid)
{
    FILE *f;
    int r;
    char *pidfile;

    pidfile=rcfg_lookup(cf, "etc.pidfile");

    if(pidfile==NULL)
        pidfile=DEFPIDFILE;

    r=checkpidfile(pidfile);

    switch(r)
    {
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
    if(NULL ==(f=fopen(pidfile, "w")) )
    {
        perror(pidfile);
        return;
    }

    fprintf(f, "%d\n", pid);

    fclose(f);
}


static void detach(void)
{
   int pid, i;
   char *tmp;

   pid=fork();

   if(pid>0)
   {
       printf("Running on PID %d\n", pid);
       writepid(pid);
       exit(0);
   }

   setsid();

   /* close uneeded file descriptors */

   for(i=0; i<256; i++)
   {
        close(i);
   }

   tmp=rcfg_lookup(cf, "etc.working_directory");
   if(tmp==NULL)
       tmp="/";

   chdir(tmp);
   umask(7);
}

static int mapcon(char *p, int stats)
{
    char key[80];
    char **list=NULL;
    struct cluster **cluster;
    char *host;
    int port, s, i, defalrm, alrm;

    _ndebug(2, ("mapcon(\"%s\", %d)\n", p, stats));

    sprintf(key, "ports.%s.tcptimeout", p);
    defalrm=rcfg_lookupInt(cf, key);
    if(defalrm<1)
        defalrm=DEFCONTIME;

    sprintf(key, "ports.%s.iscluster", p);
    if(rcfg_lookupInt(cf, key))
    {
        _ndebug(2, ("That's a cluster, do it.\n"));

       s=-1;
       /* Better check that getcluster didn't return NULL, that'd be bad */
       if( (cluster=getcluster(p, stats)) )
       {
           for(i=0; cluster[i] && s==-1; i++)
           {
               _ndebug(2, ("Trying %s:%d (alrm: %d)\n",
                       cluster[i]->hostname,
                       cluster[i]->port,
                       cluster[i]->tcptimeout));
               alarm(cluster[i]->tcptimeout);
               s=getclientsocket(cluster[i]->hostname, cluster[i]->port);
               alarm(0);
           }
       }

        freeCluster(cluster);
    }
    else
    {
        sprintf(key, "ports.%s.remote_port", p);
        _ndebug(5, ("Looking up ``%s''\n", key));
        port=rcfg_lookupInt(cf, key);
        sprintf(key, "ports.%s.remote_addr", p);
        _ndebug(5, ("Looking up ``%s''\n", key));
        host=rcfg_lookup(cf, key);

        sprintf(key, "ports.%s.tcptimeout", p);
        _ndebug(5, ("Looking up ``%s''\n", key));
        alrm=rcfg_lookupInt(cf, key);
        if(alrm<1)
           alrm=defalrm;

        _ndebug(2, ("%d seconds to connect\n", alrm));

        alarm(alrm);
        s=getclientsocket(host, port);
        alarm(0);
    }

    if(list!=NULL)
        rcfg_freeSectionList(list);
    return(s);
}

static int listento(char *gimme)
{
     char *host, *tmp, *ptr;
     int port=-1, s;

     /* as not to destroy it */
     ptr=strdup(gimme);

     host=ptr;
     for(tmp=ptr; *tmp; tmp++)
     {
        if(*tmp==':')
        {
            *tmp=NULL;
            tmp++;
            port=atoi(tmp);
        }
     }
     if(port==-1)
     {
        host=NULL;
        port=atoi(ptr);
     }

     s=getservsocket(host, port);
     free(ptr);
     return(s);
}

static void _main(void)
{
    char **ports;
    struct sockaddr_in fsin;
    int i, s, cs, os, fromlen, upper, size, selected;
    fd_set fdset, tfdset;
    int map[MAPSIZE], stats[MAPSIZE];
    char *portmap[MAPSIZE];
    char buf[BUFLEN];

    /* Initialize maps */
    for(i=0; i<MAPSIZE; i++)
    {
        map[i]=-1;
        portmap[i]=NULL;
    }

    FD_ZERO(&tfdset);
    upper=0;

    ports=rcfg_getSection(cf, "ports");
    for(i=0; ports[i]; i++)
    {
        _ndebug(0, ("Initialize port %s\n", ports[i]));
        s=listento(ports[i]);
        if(s>=0)
        {
            if(s>upper)
                upper=s;

            _ndebug(3, ("Listening on, and Fdsetting %d\n", s));
            FD_SET(s, &tfdset);
            portmap[s]=strdup(ports[i]);
        }
    }
    rcfg_freeSectionList(ports);
    upper++;

    for(;;)
    {
        fdset=tfdset;
        fromlen=sizeof(fsin);

        _ndebug(2, ("Selecting...\n"));
        if(_debug>9)
        {
            for(i=0; i<MAPSIZE; i++)
            {
                if(FD_ISSET(i, &fdset))
                   printf("    ...on %d\n", i);
            }
        }

        if( (selected=select(upper, &fdset, NULL, NULL, NULL)) > 0)
        {
            for(i=0; i<MAPSIZE; i++)
            {
                _ndebug(7, ("Testing %d for fdset\n", i));
                if(FD_ISSET(i, &fdset))
                {
                   _ndebug(2, ("Select found %d (portmaps to %s)\n",
                              i, portmap[i]));
                   if(portmap[i]!=NULL)
                   {
                        _ndebug(2, ("Got a connection for port %s\n",
                                  portmap[i]));
                        if( (cs=accept(i, (struct sockaddr *)&fsin,
                            &fromlen)) >= 0)
                        {
                          if( (os=mapcon(portmap[i], ++stats[i])) >= 0)
                          {
                              _ndebug(2, ("Got new connection, %d<->%d\n",
                                        os, cs));
                              /* Select on both directions */
                              FD_SET(cs, &tfdset);
                              FD_SET(os, &tfdset);

                          if(cs>=upper) upper=cs+1;
                          if(os>=upper) upper=os+1;

                              /* Map both directions */
                              map[cs]=os;
                              map[os]=cs;
                          }
                          else
                          {
                              close(cs);
                          }
                        }
                   }
                   else /* We've got data, need to send it */
                   {
                       _ndebug(2, ("That's a listener\n"));
                       if(map[i]>0)
                       {
                          size=recv(i, buf, BUFLEN, 0);
                          if(size==0)
                          {
                              close(i);
                              close(map[i]);
                              FD_CLR(i, &tfdset);
                              FD_CLR(map[i], &tfdset);
                              map[map[i]]=-1;
                              map[i]=-1;
                          }
                          else
                          {
                              _ndebug(3, ("Sending %d bytes from %d "
                                        "to %d\n", size, i, map[i]));
                              send(map[i], buf, size, 0);
                          }
                       }
                   }
                   if(--selected==0)
                   {
                       _ndebug(4, ("Select done\n"));
                       break;
                   }
                } /* End of ``that bastard i's selected'' if statement */
            } /* End of ``flip through select'' loop */
        }
        else
        {
            perror("Select");
            exit(0);
        }
    } /* Infinite loop */
}

void main(void)
{
    resettraps();
    cf=rcfg_readconfig(CONFFILE);
    _debug=rcfg_lookupInt(cf, "etc.debug");
    if(_debug==0)
        detach();
    _main();
}
