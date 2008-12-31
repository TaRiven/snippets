/*
 * Copyright (c) 1998  Dustin Sallings
 *
 * $Id: hash.c,v 1.2 2000/07/30 03:01:48 dustin Exp $
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "mymalloc.h"
#include "acct.h"
#include "hash.h"

#define _do_hash(a, b) (b%a->hashsize)

/* Initialize a hash table */
struct hashtable *
hash_init(int size)
{
	struct hashtable *hash;

	hash = calloc(1, sizeof(struct hashtable));
	assert(hash);

	hash->hashsize = size;

	hash->buckets = calloc(hash->hashsize, sizeof(struct hash_container *));
	assert(hash->buckets);

	return (hash);
}

/* Store something in a hash table */
struct hash_container *
hash_store(struct hashtable *hash, unsigned int key)
{
	struct hash_container *c, *p;
	int     hashval;

	c = calloc(1, sizeof(struct hash_container));
	assert(c);

	c->key = key;

	c->value = 0;
	c->next = NULL;

	hashval = _do_hash(hash, key);

	p = hash->buckets[hashval];

	if (p) {
		for (; p->next; p = p->next);
		p->next = c;
	} else {
		hash->buckets[hashval] = c;
	}

	return (c);
}

struct hash_container *hash_add(struct hashtable *hash,
	unsigned int key, int value)
{
	struct hash_container *c;

	c=hash_find(hash, key);
	if(c==NULL) {
		c=hash_store(hash, key);
	}

	c->value+=value;
	return(c);
}

/* find a key in a hash table */
struct hash_container *
hash_find(struct hashtable *hash, unsigned int key)
{
	struct hash_container *p;
	int     hashval;

	if(hash==NULL)
		return(NULL);

	hashval = _do_hash(hash, key);

	assert(hashval >= 0);
	assert(hashval < hash->hashsize);

	p = hash->buckets[hashval];

	for (; p; p = p->next) {
		if (p->key==key)
			break;
	}

	return (p);
}

/* Delete an entry from the hash table */
void
hash_delete(struct hashtable *hash, unsigned int key)
{
	struct hash_container *p, *deleteme = NULL;
	int     hashval;

	hashval = _do_hash(hash, key);
	p = hash->buckets[hashval];

	for (; p->next; p = p->next) {
		if (p->key == key)
			break;
	}

	if (!p->next) {
		/* Stopped for a reason other than a match, rewind the bucket, and
		 * check the first key */
		p = hash->buckets[hashval];
		if (p->key==key) {
			deleteme = p;
			hash->buckets[hashval] = p->next;
		}
	} else {
		deleteme = p->next;
		p->next = p->next->next;
	}

	if (deleteme) {
		free(deleteme);
		deleteme = NULL;
	}
}

/* Destroy a hash */
void
hash_destroy(struct hashtable *hash)
{
	int    i;
	struct hash_keylist keys;

	if (hash == 0)
		return;

	keys = hash_keys(hash);

	for (i = 0; i<keys.nentries; i++) {
		hash_delete(hash, keys.entries[i]);
	}

	free(keys.entries);

	if (hash->buckets)
		free(hash->buckets);
	free(hash);
}

struct hash_keylist hash_keys(struct hashtable *hash)
{
	int    size = 4096, i;
	struct hash_container *p;
	struct hash_keylist list;

	list.nentries=0;
	list.entries= (int *) malloc(size * sizeof(int));
	assert(list.entries);

#define LAPPEND(a) if(list.nentries == size-1) { \
        list.entries=realloc(list.entries, (size<<=1)*sizeof(int)); \
            assert(list.entries); \
    } \
    list.entries[list.nentries++]=a;

	for (i = 0; i < hash->hashsize; i++) {
		p = hash->buckets[i];

		if (p) {
			for (; p; p = p->next) {
				LAPPEND(p->key);
			}
		}
	}
	return (list);
}

/* debug stuff, dump the hash */
void
_hash_dump(struct hashtable *hash)
{
	struct hash_container *p;
	int     i;

	printf("Hash dump for hash at %p, size is %d:\n", hash, hash->hashsize);

	for (i = 0; i < hash->hashsize; i++) {
		p = hash->buckets[i];

		if (p) {
			printf("\tMatches at %d\n", i);
			for (; p; p = p->next) {
#ifdef MYMALLOC
				if (_lookup_mem(p) == NULL) {
					printf("MEMORY IS INVALID!!! (%p)\n", p);
					_mdebug_dump();
				}
#endif
				printf("\t\t%s=%d\n", ntoa(p->key), p->value);
			}
		}
	}
}
