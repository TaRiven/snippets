/*
 * Copyright (c) 1998  Dustin Sallings
 *
 * $Id: hash.h,v 1.1 1999/05/08 21:17:51 dustin Exp $
 */

#ifndef HASH_H
#define HASH_H 1

#define HASHSIZE 16369

#include <stdlib.h>

struct hash_container {
	int    key;
	void   *value;
	struct hash_container *next;
};

struct hashtable {
	int    hashsize;
	struct hash_container **buckets;
};

struct hashtable *hash_init(int size);
struct hash_container *hash_store(struct hashtable *hash,
    int key, void *data);
struct hash_container *hash_find(struct hashtable *hash, int key);
void    hash_delete(struct hashtable *hash, int key);
void    hash_destroy(struct hashtable *hash);
void    _hash_dump(struct hashtable *hash);

#endif /* HASH_H */
