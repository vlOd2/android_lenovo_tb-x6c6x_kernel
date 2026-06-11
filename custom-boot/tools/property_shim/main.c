#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <inttypes.h>
#include <stdarg.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <dlfcn.h>
#include <errno.h>

#define PROP_DB_PATH "/data/shim_props.prop"
#define MAX_LINE 1024
#define MAX_KEY 256
#define MAX_VAL 512

typedef int (*real_open_fn)(const char *pathname, int flags, ...);
typedef int (*real_access_fn)(const char *pathname, int mode);
typedef int (*real_stat_fn)(const char *pathname, struct stat *st);
typedef int (*real_ioctl_fn)(int fd, int request, ...);

static int debug_enabled(void) {
    return getenv("PROP_SHIM_DEBUG") != NULL;
}

static void debug_log(const char *fmt, ...) {
    if (!debug_enabled()) return;
    va_list ap;
    va_start(ap, fmt);
    fprintf(stderr, "[property_shim] ");
    vfprintf(stderr, fmt, ap);
    fprintf(stderr, "\n");
    va_end(ap);
}

static void log_call(const char *fn, const char *key, const char *val, const char *out) {
    fprintf(stderr, "[property_shim] %s(\"%s\", \"%s\") -> %s\n",
            fn,
            key ? key : "(null)",
            val ? val : "(null)",
            out ? out : "(null)");
}

static const char *fallback_paths[] = {
    "/vendor/etc/rsc/default/ro.prop",
    "/vendor/etc/rsc/default/rw.prop",
    "/vendor/etc/rsc/master_wifi/ro.prop",
    "/vendor/etc/rsc/master_wifi/rw.prop",
    "/vendor/default.prop",
    "/vendor/build.prop",
};

static void copy_small(char *dst, const char *src) {
    if (!dst) return;
    if (!src) src = "";
    size_t n = strlen(src);
    if (n > 31) n = 31;
    memcpy(dst, src, n);
    dst[n] = '\0';
}

static int read_prop_file(const char *path, const char *key, char *out, size_t outsz) {
    FILE *f = fopen(path, "r");
    if (!f) return 0;

    char line[MAX_LINE];
    while (fgets(line, sizeof(line), f)) {
        char *s = line;
        while (*s == ' ' || *s == '\t') s++;
        if (*s == '#' || *s == '\n' || *s == '\0') continue;

        char *eq = strchr(s, '=');
        if (!eq) continue;

        *eq = '\0';
        char *k = s;
        char *v = eq + 1;

        k[strcspn(k, "\r\n")] = '\0';
        v[strcspn(v, "\r\n")] = '\0';

        if (strcmp(k, key) == 0) {
            snprintf(out, outsz, "%s", v);
            fclose(f);
            return 1;
        }
    }

    fclose(f);
    return 0;
}

static const char *lookup_property(const char *key, char *buf, size_t bufsz) {
    if (read_prop_file(PROP_DB_PATH, key, buf, bufsz)) {
        return buf;
    }

    for (size_t i = 0; i < sizeof(fallback_paths) / sizeof(fallback_paths[0]); i++) {
        if (read_prop_file(fallback_paths[i], key, buf, bufsz)) {
            return buf;
        }
    }

    buf[0] = '\0';
    return buf;
}

static int append_prop_file(const char *path, const char *key, const char *value) {
    FILE *in = fopen(path, "r");
    char lines[256][MAX_LINE];
    size_t nlines = 0;
    int replaced = 0;

    if (in) {
        while (fgets(lines[nlines], sizeof(lines[nlines]), in)) {
            if (nlines + 1 >= 256) break;
            nlines++;
        }
        fclose(in);
    }

    char tmp_path[sizeof(PROP_DB_PATH) + 8];
    snprintf(tmp_path, sizeof(tmp_path), "%s.tmp", path);

    FILE *out = fopen(tmp_path, "w");
    if (!out) return -1;

    for (size_t i = 0; i < nlines; i++) {
        char *line = lines[i];
        char *s = line;
        while (*s == ' ' || *s == '\t') s++;

        char *eq = strchr(s, '=');
        if (eq) {
            *eq = '\0';
            char *k = s;
            k[strcspn(k, "\r\n")] = '\0';
            if (strcmp(k, key) == 0) {
                fprintf(out, "%s=%s\n", key, value ? value : "");
                replaced = 1;
                continue;
            }
        }
        fputs(line, out);
        if (line[strlen(line) - 1] != '\n') fputc('\n', out);
    }

    if (!replaced) {
        fprintf(out, "%s=%s\n", key, value ? value : "");
    }

    fflush(out);
    fsync(fileno(out));
    fclose(out);

    if (rename(tmp_path, path) != 0) {
        unlink(tmp_path);
        return -1;
    }
    return 0;
}

static int store_property(const char *key, const char *value) {
    return append_prop_file(PROP_DB_PATH, key, value);
}

/* ---------------- property APIs ---------------- */

int property_get(const char *key, char *value, const char *default_value) {
    char tmp[MAX_VAL];
    const char *v = lookup_property(key, tmp, sizeof(tmp));
    if (!v || !*v) v = default_value ? default_value : "";
    copy_small(value, v);
    log_call("property_get", key, default_value, v);
    return (int)strlen(v);
}

int property_set(const char *key, const char *value) {
    int ret = store_property(key, value ? value : "");
    log_call("property_set", key, value, ret == 0 ? "0" : "-1");
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
    log_call("property_get_bool", key, NULL, buf);
    return out;
}

int32_t property_get_int32(const char *key, int32_t default_value) {
    char tmp[MAX_VAL];
    const char *v = lookup_property(key, tmp, sizeof(tmp));
    int32_t out = default_value;
    if (v && *v) out = (int32_t)strtol(v, NULL, 0);

    char buf[64];
    snprintf(buf, sizeof(buf), "%" PRId32, out);
    log_call("property_get_int32", key, NULL, buf);
    return out;
}

int64_t property_get_int64(const char *key, int64_t default_value) {
    char tmp[MAX_VAL];
    const char *v = lookup_property(key, tmp, sizeof(tmp));
    int64_t out = default_value;
    if (v && *v) out = (int64_t)strtoll(v, NULL, 0);

    char buf[64];
    snprintf(buf, sizeof(buf), "%" PRId64, out);
    log_call("property_get_int64", key, NULL, buf);
    return out;
}

int __system_property_get(const char *name, char *value) {
    char tmp[MAX_VAL];
    const char *v = lookup_property(name, tmp, sizeof(tmp));
    copy_small(value, v);
    log_call("__system_property_get", name, NULL, v);
    return (int)strlen(v);
}

int __system_property_set(const char *name, const char *value) {
    int ret = store_property(name, value ? value : "");
    log_call("__system_property_set", name, value, ret == 0 ? "0" : "-1");
    return ret == 0 ? 0 : -1;
}

void __system_property_foreach(void *cb, void *cookie) {
    (void)cb;
    (void)cookie;
    debug_log("__system_property_foreach() called");
}

/* ---------------- debug hooks ---------------- */

static int path_matches(const char *path) {
    if (!path) return 0;
    return !strncmp(path, "/dev/", 5) ||
           !strncmp(path, "/proc/driver/", 13) ||
           !strncmp(path, "/vendor/firmware/", 17) ||
           !strncmp(path, "/system/vendor/firmware/", 24);
}

int open(const char *pathname, int flags, ...) {
    static real_open_fn real_open = NULL;
    if (!real_open) real_open = (real_open_fn)dlsym(RTLD_NEXT, "open");

    mode_t mode = 0;
    if (flags & O_CREAT) {
        va_list ap;
        va_start(ap, flags);
        mode = (mode_t)va_arg(ap, int);
        va_end(ap);
    }

    if (debug_enabled() && path_matches(pathname)) {
        debug_log("open(\"%s\", 0x%x)", pathname ? pathname : "(null)", flags);
    }

    if (flags & O_CREAT)
        return real_open(pathname, flags, mode);
    return real_open(pathname, flags);
}

int access(const char *pathname, int mode) {
    static real_access_fn real_access = NULL;
    if (!real_access) real_access = (real_access_fn)dlsym(RTLD_NEXT, "access");

    if (debug_enabled() && path_matches(pathname)) {
        debug_log("access(\"%s\", 0x%x)", pathname ? pathname : "(null)", mode);
    }

    return real_access(pathname, mode);
}

int stat(const char *pathname, struct stat *st) {
    static real_stat_fn real_stat = NULL;
    if (!real_stat) real_stat = (real_stat_fn)dlsym(RTLD_NEXT, "stat");

    if (debug_enabled() && path_matches(pathname)) {
        debug_log("stat(\"%s\")", pathname ? pathname : "(null)");
    }

    return real_stat(pathname, st);
}

int ioctl(int fd, int request, ...) {
    static real_ioctl_fn real_ioctl = NULL;
    if (!real_ioctl) real_ioctl = (real_ioctl_fn)dlsym(RTLD_NEXT, "ioctl");

    va_list ap;
    void *arg = NULL;
    va_start(ap, request);
    arg = va_arg(ap, void *);
    va_end(ap);

    if (debug_enabled()) {
        debug_log("ioctl(fd=%d, request=0x%lx, arg=%p)", fd, request, arg);
    }

    return real_ioctl(fd, request, arg);
}