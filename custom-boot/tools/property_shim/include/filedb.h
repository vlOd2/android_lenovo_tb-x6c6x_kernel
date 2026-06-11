#ifndef FILEDB_H
#define FILEDB_H

#include "util.h"

#define MAX_LINE 1024
#define MAX_KEY 256
#define MAX_VAL 512

int read_prop_file(const char *path, const char *key, char *out, size_t outsz);

const char *lookup_property(const char *key, char *buf, size_t bufsz);

int append_prop_file(const char *path, const char *key, const char *value);

int store_property(const char *key, const char *value);

#endif