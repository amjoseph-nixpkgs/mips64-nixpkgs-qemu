```
$ nix-shell

this derivation will be built:
  /nix/store/iydy2n6jnmdam4wrb4gyvww2gdhfx695-mips64el-qemu-linux-initrd.drv
building '/nix/store/iydy2n6jnmdam4wrb4gyvww2gdhfx695-mips64el-qemu-linux-initrd.drv'...
building
installing
/nix/store/r0qppp14jjxd695wb6ad6d15n49x6hzp-mips64el-qemu-linux-initrd/initrd.gz
[    0.000000] Linux version 5.10.88 (nix@moore) (mips64el-linux-gnuabi64-gcc (GCC) 10.3.0, GNU ld (GNU Binutils) 2.35.2) #1-NixOS SMP Wed Dec 22 08:31:00 UTC 2021
[    0.000000] earlycon: uart8250 at I/O port 0x3f8 (options '38400n8')
[    0.000000] printk: bootconsole [uart8250] enabled
[    0.000000] MIPS CPS SMP unable to proceed without a CM
...
[    2.583682] Run /init as init process
/ # ls -l hello-from-nix
lrwxrwxrwx    1 0        0               99 Mar  1 14:23 hello-from-nix -> /nix/store/qf0lmqx4ihri306cws9dlcq776zbfhjg-hello-static-mips64el-unknown-linux-musl-2.10/bin/hello
/ # ./hello-from-nix
Hello, world!
```