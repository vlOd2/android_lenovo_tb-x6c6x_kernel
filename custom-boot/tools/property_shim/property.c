#include "include/property.h"

int property_get(const char *key, char *value, const char *default_value) {
    char tmp[MAX_VAL];
    const char *v = lookup_property(key, tmp, sizeof(tmp));
    if (!v || !*v) {
        v = default_value ? default_value : "";
    }
    copy_small(value, v);
    debug_log_prop("property_get", key, default_value, v);
    return (int)strlen(v);
}

int property_set(const char *key, const char *value) {
    int ret = store_property(key, value ? value : "");
    debug_log_prop("property_set", key, value, ret == 0 ? "0" : "-1");
    return ret == 0 ? 0 : -1;
}

int property_get_bool(const char *key, int default_value) {
    char tmp[MAX_VAL];
    const char *v = lookup_property(key, tmp, sizeof(tmp));
    int out = default_value;

    if (v && *v) {
        if (!strcmp(v, "1") || !strcmp(v, "true") || !strcmp(v, "y") || !strcmp(v, "yes"))
            out = 1;
        else if (!strcmp(v, "0") || !strcmp(v, "false") || !strcmp(v, "n") || !strcmp(v, "no"))
            out = 0;
    }

    char buf[32];
    snprintf(buf, sizeof(buf), "%d", out);
    debug_log_prop("property_get_bool", key, NULL, buf);

    return out;
}

int32_t property_get_int32(const char *key, int32_t default_value) {
    char tmp[MAX_VAL];
    const char *v = lookup_property(key, tmp, sizeof(tmp));

    int32_t out = default_value;
    if (v && *v) {
        out = (int32_t)strtol(v, NULL, 0);
    }

    char buf[64];
    snprintf(buf, sizeof(buf), "%" PRId32, out);
    debug_log_prop("property_get_int32", key, NULL, buf);

    return out;
}

int64_t property_get_int64(const char *key, int64_t default_value) {
    char tmp[MAX_VAL];
    const char *v = lookup_property(key, tmp, sizeof(tmp));

    int64_t out = default_value;
    if (v && *v) {
        out = (int64_t)strtoll(v, NULL, 0);
    }

    char buf[64];
    snprintf(buf, sizeof(buf), "%" PRId64, out);
    debug_log_prop("property_get_int64", key, NULL, buf);

    return out;
}

int __system_property_get(const char *name, char *value) {
    char tmp[MAX_VAL];
    const char *v = lookup_property(name, tmp, sizeof(tmp));
    copy_small(value, v);
    debug_log_prop("__system_property_get", name, NULL, v);
    return (int)strlen(v);
}

int __system_property_set(const char *name, const char *value) {
    int ret = store_property(name, value ? value : "");
    debug_log_prop("__system_property_set", name, value, ret == 0 ? "0" : "-1");
    return ret == 0 ? 0 : -1;
}

int __system_property_foreach(void *cb, void *cookie) {
    (void)cb;
    (void)cookie;
    fprintf(stderr, "__system_property_foreach() stub called");
    return 0;
}