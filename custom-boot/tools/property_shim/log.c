#include "include/log.h"

static int is_debug_enabled = 0;
static int is_verbose_debug_enabled = 0;
static int is_bytes_dumping_enabled = 0;

__attribute__((constructor))
static void init_debug_flag() {
    is_debug_enabled = getenv("PROP_SHIM_DEBUG") != NULL;
    is_verbose_debug_enabled = getenv("PROP_SHIM_VERBOSE_DEBUG") != NULL;
    is_bytes_dumping_enabled = getenv("PROP_SHIM_DUMP_BYTES") != NULL;
}

int debug_enabled() {
    return is_debug_enabled;
}

int debug_verbose_enabled() {
    return is_debug_enabled && is_verbose_debug_enabled;
}

void debug_log_prop(const char *fn, const char *key, const char *val, const char *out) {
    if (!debug_enabled()) return;
    fprintf(stderr, "[property_shim] %s(\"%s\", \"%s\") -> %s\n",
            fn,
            key ? key : "(null)",
            val ? val : "(null)",
            out ? out : "(null)");
}

void debug_verbose_log(const char *fmt, ...) {
    if (!debug_verbose_enabled()) return;
    va_list ap;
    va_start(ap, fmt);
    fprintf(stderr, "[property_shim] ");
    vfprintf(stderr, fmt, ap);
    fprintf(stderr, "\n");
    va_end(ap);
}

// only available in verbose mode
void debug_dump_bytes(const char *label, const void *buf, size_t count) {
    if (!debug_verbose_enabled() || !is_bytes_dumping_enabled) return;

    if (!buf || count == 0) {
        debug_verbose_log("%s: <empty>", label);
        return;
    }

    size_t n = count;
    if (n > 96) n = 96;

    const unsigned char *p = (const unsigned char *)buf;
    char hex[96 * 3 + 1];
    char *out = hex;

    for (size_t i = 0; i < n; i++) {
        snprintf(out, 4, "%02x ", p[i]);
        out += 3;
    }
    *out = '\0';

    debug_verbose_log("%s (%zu bytes): %s%s", label, count, hex, (count > n) ? "..." : "");
}
