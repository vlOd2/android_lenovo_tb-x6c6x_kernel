#ifndef UTIL_H
#define UTIL_H

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

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

#define EXPORT __attribute__((visibility("default")))

static void copy_small(char *dst, const char *src) {
    if (!dst) return;
    if (!src) src = "";
    size_t n = strlen(src);
    if (n > 31) n = 31;
    memcpy(dst, src, n);
    dst[n] = '\0';
}

#endif