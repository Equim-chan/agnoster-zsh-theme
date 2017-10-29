#include <stdlib.h>
#include <stdio.h>

#include <unistd.h>
#include <fcntl.h>

#define FATAL(code, msg) do { \
    fputs(msg, stderr); \
    exit(code); \
} while (0);


int main()
{
    int fd, n;
    char buf[128];
    double avg_1;

    // 这里直接用 open(3) 这个 POSIX syscall
    fd = open("/proc/loadavg", O_RDONLY);
    if (fd == -1) {
        FATAL(1, "failed open /proc/loadavg\n");
    }

    // 这句是整个程序的核心，不能少！
    // 如果没有这句，每次获取 /proc/loadavg 的结果都不会变
    // 原因不明
    n = lseek(fd, 0, SEEK_SET);
    if (n == -1) {
        close(fd);
        FATAL(1, "failed seek /proc/loadavg\n");
    }

    n = read(fd, buf, 128);
    close(fd);
    if (n == -1) {
        FATAL(1, "failed read /proc/loadavg\n");
    }

    n = sscanf(buf, "%lf", &avg_1);
    if (n < 1) {
        FATAL(1, "bad data in /proc/loadavg\n");
    }

#ifdef AS_ONE_CORE
    printf("%.2lf", avg_1 / sysconf(_SC_NPROCESSORS_ONLN));
#else
    printf("%.2lf", avg_1);
#endif

    return 0;
}
