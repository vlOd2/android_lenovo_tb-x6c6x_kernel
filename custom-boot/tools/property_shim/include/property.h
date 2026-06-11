#ifndef PROPERTY_H
#define PROPERTY_H

#include "util.h"
#include "filedb.h"
#include "log.h"

EXPORT int property_get(const char *key, char *value, const char *default_value);

EXPORT int property_set(const char *key, const char *value);

EXPORT int property_get_bool(const char *key, int default_value);

EXPORT int32_t property_get_int32(const char *key, int32_t default_value);

EXPORT int64_t property_get_int64(const char *key, int64_t default_value);

EXPORT int __system_property_get(const char *name, char *value);

EXPORT int __system_property_set(const char *name, const char *value);

EXPORT int __system_property_foreach(void *cb, void *cookie);

#endif