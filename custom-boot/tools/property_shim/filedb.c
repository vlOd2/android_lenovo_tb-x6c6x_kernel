#include "include/filedb.h"

#define PROP_DB_PATH "/data/shim_props.prop"

static const char *fallback_paths[] = {
    "/vendor/etc/rsc/default/ro.prop",
    "/vendor/etc/rsc/default/rw.prop",
    "/vendor/etc/rsc/master_wifi/ro.prop",
    "/vendor/etc/rsc/master_wifi/rw.prop",
    "/vendor/default.prop",
    "/vendor/build.prop",
};

int read_prop_file(const char *path, const char *key, char *out, size_t outsz) {
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

const char *lookup_property(const char *key, char *buf, size_t bufsz) {
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

int append_prop_file(const char *path, const char *key, const char *value) {
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

int store_property(const char *key, const char *value) {
    return append_prop_file(PROP_DB_PATH, key, value);
}
