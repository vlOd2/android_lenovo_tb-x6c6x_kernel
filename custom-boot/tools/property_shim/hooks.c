#include "include/util.h"
#include "include/log.h"

#ifdef INCLUDE_DEBUG_HOOKS

typedef int (*real_open_fn)(const char *pathname, int flags, ...);
typedef int (*real_access_fn)(const char *pathname, int mode);
typedef int (*real_stat_fn)(const char *pathname, struct stat *st);
typedef int (*real_ioctl_fn)(int fd, int request, ...);
typedef ssize_t (*real_read_fn)(int, void *, size_t);
typedef ssize_t (*real_write_fn)(int, const void *, size_t);
typedef int (*real_inotify_init_fn)(void);
typedef int (*real_inotify_add_watch_fn)(int, const char *, uint32_t);
typedef int (*real_inotify_rm_watch_fn)(int, int);

static __thread int in_hook = 0;

static int path_matches(const char *path) {
    if (!path) return 0;
    return !strncmp(path, "/dev/", 5) ||
           !strncmp(path, "/proc/driver/", 13) ||
           !strncmp(path, "/vendor/firmware/", 17) ||
           !strncmp(path, "/system/vendor/firmware/", 24);
}

EXPORT int open(const char *pathname, int flags, ...) {
    static real_open_fn real_open = NULL;
    if (!real_open) real_open = (real_open_fn)dlsym(RTLD_NEXT, "open");

    mode_t mode = 0;
    if (flags & O_CREAT) {
        va_list ap;
        va_start(ap, flags);
        mode = (mode_t)va_arg(ap, int);
        va_end(ap);
    }

    if (debug_verbose_enabled() && path_matches(pathname)) {
        debug_log("open(\"%s\", 0x%x)", pathname ? pathname : "(null)", flags);
    }

    if (flags & O_CREAT)
        return real_open(pathname, flags, mode);
    return real_open(pathname, flags);
}

EXPORT int access(const char *pathname, int mode) {
    static real_access_fn real_access = NULL;
    if (!real_access) real_access = (real_access_fn)dlsym(RTLD_NEXT, "access");

    if (debug_verbose_enabled() && path_matches(pathname)) {
        debug_log("access(\"%s\", 0x%x)", pathname ? pathname : "(null)", mode);
    }

    return real_access(pathname, mode);
}

EXPORT int stat(const char *pathname, struct stat *st) {
    static real_stat_fn real_stat = NULL;
    if (!real_stat) real_stat = (real_stat_fn)dlsym(RTLD_NEXT, "stat");

    if (debug_verbose_enabled() && path_matches(pathname)) {
        debug_log("stat(\"%s\")", pathname ? pathname : "(null)");
    }

    return real_stat(pathname, st);
}

EXPORT int ioctl(int fd, int request, ...) {
    static real_ioctl_fn real_ioctl = NULL;
    if (!real_ioctl) real_ioctl = (real_ioctl_fn)dlsym(RTLD_NEXT, "ioctl");

    va_list ap;
    void *arg = NULL;
    va_start(ap, request);
    arg = va_arg(ap, void *);
    va_end(ap);

    if (debug_verbose_enabled()) {
        debug_log("ioctl(fd=%d, request=0x%lx, arg=%p)", fd, request, arg);
    }

    return real_ioctl(fd, request, arg);
}

EXPORT ssize_t read(int fd, void *buf, size_t count) {
    static real_read_fn real_read = NULL;
    if (!real_read) real_read = (real_read_fn)dlsym(RTLD_NEXT, "read");

    ssize_t ret = real_read(fd, buf, count);
    if (debug_verbose_enabled()) {
        debug_log("read(fd=%d, count=%zu) -> %zd", fd, count, ret);
        if (ret > 0) dump_bytes("read data", buf, (size_t)ret);
    }
    
    return ret;
}

EXPORT ssize_t write(int fd, const void *buf, size_t count) {
    static real_write_fn real_write = NULL;
    if (!real_write) real_write = (real_write_fn)dlsym(RTLD_NEXT, "write");

    if (in_hook) {
        return real_write(fd, buf, count);
    }

    in_hook = 1;
    if (debug_verbose_enabled()) {
        debug_log("write(fd=%d, count=%zu)", fd, count);
        dump_bytes("write data", buf, count);
    }
    ssize_t ret = real_write(fd, buf, count);
    in_hook = 0;

    return ret;
}

EXPORT int inotify_init(void) {
    static real_inotify_init_fn real_inotify_init = NULL;
    if (!real_inotify_init) real_inotify_init = (real_inotify_init_fn)dlsym(RTLD_NEXT, "inotify_init");

    int ret = real_inotify_init();
    if (debug_verbose_enabled()) {
        debug_log("inotify_init() -> %d", ret);
    }

    return ret;
}

EXPORT int inotify_add_watch(int fd, const char *pathname, uint32_t mask) {
    static real_inotify_add_watch_fn real_inotify_add_watch = NULL;
    if (!real_inotify_add_watch) real_inotify_add_watch = (real_inotify_add_watch_fn)dlsym(RTLD_NEXT, "inotify_add_watch");

    if (debug_verbose_enabled()) {
        debug_log("inotify_add_watch(fd=%d, path=\"%s\", mask=0x%x)", fd, pathname ? pathname : "(null)", mask);
    }

    return real_inotify_add_watch(fd, pathname, mask);
}

EXPORT int inotify_rm_watch(int fd, int wd) {
    static real_inotify_rm_watch_fn real_inotify_rm_watch = NULL;
    if (!real_inotify_rm_watch) real_inotify_rm_watch = (real_inotify_rm_watch_fn)dlsym(RTLD_NEXT, "inotify_rm_watch");

    int ret = real_inotify_rm_watch(fd, wd);
    if (debug_verbose_enabled()) {
        debug_log("inotify_rm_watch(fd=%d, wd=%d) -> %d", fd, wd, ret);
    }

    return ret;
}

#endif