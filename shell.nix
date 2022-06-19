{ NIXPATH }:
with import <nixpkgs> { };

let
  bootstrap-files = (import <nixpkgs/pkgs/stdenv/linux/make-bootstrap-tools-cross.nix> { }).mips64el-linux-gnuabi64.build;
  static-nix = pkgs.pkgsCross.mips64el-linux-gnuabi64.pkgsStatic.nix_2_4;
  hello   = pkgs.pkgsCross.mips64el-linux-gnuabi64.pkgsStatic.hello;
  busybox = pkgs.pkgsCross.mips64el-linux-gnuabi64.pkgsStatic.busybox;
  kernel  = pkgs.pkgsCross.mips64el-qemu-linux-gnuabi64.linux;
  initrd = stdenv.mkDerivation {
    name = "mips64el-qemu-linux-initrd";
    dontUnpack = true;
    buildInputs = [ hello busybox ];
    nativeBuildInputs = [ cpio gzip ];
    strictDeps = true;
    passAsFile = [ "initscript" "fstab" "inittab" ];
    inittab = ''
      console::askfirst:-/bin/sh
    '';
    fstab = ''
      devpts          /dev/pts        devpts  defaults                  0 0
      tmpfs           /run            tmpfs   nosuid,size=10%,mode=755  0 0
      proc            /proc           proc    defaults                  0 0
      sysfs           /sys            sysfs   noauto                    0 0
      nixstore        /host/nix/store 9p      ro,msize=524288           0 0
      nixpkgs         /host/nixpkgs   9p      ro,msize=524288           0 0
    '';
    initscript = ''
      #!/bin/sh
      mount -a
      mknod /dev/urandom c 1 9
      mknod /dev/null c 1 3
      mknod /dev/ptmx c 5 2
      /bin/sh
      reboot -f   # exit qemu
      '';
    buildPhase = ''
      mkdir initrd
      cd initrd
      mkdir -p bin etc dev dev/pts run proc sys initrd tmp nix host/nix/store host/nixpkgs
      ln -s bin sbin
      ln -s ${hello.out}/bin/hello hello-from-nix
      ln -s /host/${bootstrap-files.out} bootstrap-files
      ln -s /host/${static-nix.out} static-nix
      cp -r ${busybox.out}/bin/* bin/
      cp $initscriptPath init
      chmod +x init
      cp $inittabPath etc/inittab
      cp $fstabPath etc/fstab
    '';
    installPhase = ''
      mkdir $out
      find . | cpio --quiet --create -H newc | GZIP= gzip > $out/initrd.gz
    '';
  };

  builder = "${pkgs.qemu}/bin/qemu-system-mips64el";
  args = [
    "-M" "malta"
    "-cpu" "5KEc"
    "-m" "1024"
    "-nographic"
    "-no-reboot"  # shutdown means exit
    "-kernel" "${kernel}/vmlinuz-${kernel.version}"
    "-initrd" "${initrd}/initrd.gz"
    "-net" "none"
    "-vga" "none"
    "-fsdev" "local,path=/nix/store,security_model=none,id=nixstore,readonly=on"
    "-device" "virtio-9p-pci,fsdev=nixstore,mount_tag=nixstore"
    "-fsdev" "local,path=${NIXPATH}/nixpkgs,security_model=none,id=nixpkgs,readonly=on"
    "-device" "virtio-9p-pci,fsdev=nixpkgs,mount_tag=nixpkgs"
    "-append" "console=ttyS0 init=/bin/sh"
  ];
in

# you MUST use nix-shell here; qemu needs to grab the pty, and no
# other invocation of the nixtools will give it the pty
stdenv.mkDerivation {
  system = stdenv.hostPlatform.system;
  name = "run-qemu-system-mips64el";
  builder = builder;
  args = args;

  shellHook =
    builder
    + " "
    + lib.concatStringsSep " " (builtins.map (x: "\'"+x+"\'") args)
    + "; exit";
}
