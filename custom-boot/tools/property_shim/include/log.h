#ifndef LOG_H
#define LOG_H

#include "util.h"

int debug_enabled();

int debug_verbose_enabled();

void debug_log_prop(const char *fn, const char *key, const char *val, const char *out);

void debug_verbose_log(const char *fmt, ...);

void debug_dump_bytes(const char *label, const void *buf, size_t count);

#endif