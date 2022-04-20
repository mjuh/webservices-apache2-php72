{ nixpkgs }:

with nixpkgs;

let
  inherit (builtins) concatMap getEnv toJSON;
  inherit (dockerTools) buildLayeredImage;
  inherit (lib) concatMapStringsSep firstNChars flattenSet dockerRunCmd mkRootfs;
  inherit (lib.attrsets) collect isDerivation;
  inherit (stdenv) mkDerivation;

  php72DockerArgHints = lib.phpDockerArgHints { php = php72; };

  rootfs = mkRootfs {
    name = "apache2-rootfs-php72";
    src = ./rootfs;
    inherit zlib curl coreutils findutils apacheHttpdmpmITK apacheHttpd
      s6 execline php72 logger;
    mjHttpErrorPages = mj-http-error-pages;
    postfix = sendmail;
    mjperl5Packages = mjperl5lib;
    ioncube = ioncube.v72;
    s6PortableUtils = s6-portable-utils;
    s6LinuxUtils = s6-linux-utils;
    mimeTypes = mime-types;
    libstdcxx = gcc-unwrapped.lib;
  };

in

pkgs.dockerTools.buildLayeredImage rec {
  name = "docker-registry.intr/webservices/apache2-php72";
  tag = "latest";
  contents = [
    rootfs
    tzdata
    apacheHttpd
    locale
    sendmail
    sh
    coreutils
    libjpeg_turbo
    jpegoptim
    (optipng.override { inherit libpng; })
    imagemagickBig
    ghostscript
    gifsicle
    nss-certs.unbundled
    zip
    gcc-unwrapped.lib
    glibc
    zlib
    mariadbConnectorC
    logger
    perl520
    gifsicle
    ghostscript
    nodePackages.svgo
  ]
  ++ collect isDerivation php72Packages
  ++ collect isDerivation mjperl5Packages;
  config = {
    Entrypoint = [ "${rootfs}/init" ];
    Env = [
      "TZ=Europe/Moscow"
      "TZDIR=${tzdata}/share/zoneinfo"
      "LOCALE_ARCHIVE_2_27=${locale}/lib/locale/locale-archive"
      "LOCALE_ARCHIVE=${locale}/lib/locale/locale-archive"
      "LC_ALL=en_US.UTF-8"
      "LD_PRELOAD=${jemalloc}/lib/libjemalloc.so"
      "PERL5LIB=${mjPerlPackages.PERL5LIB}"
    ];
    Labels = flattenSet rec {
      ru.majordomo.docker.arg-hints-json = builtins.toJSON php72DockerArgHints;
      ru.majordomo.docker.cmd = dockerRunCmd php72DockerArgHints "${name}:${tag}";
      ru.majordomo.docker.exec.reload-cmd = "${apacheHttpd}/bin/httpd -d ${rootfs}/etc/httpd -k graceful";
    };
  };
  extraCommands = ''
    set -xe
    ls
    mkdir -p etc
    mkdir -p bin
    mkdir -p usr/local
    mkdir -p opt
    chmod 755 bin
    ln -s ${nodePackages.svgo}/bin/svgo bin/svgo
    ln -s ${php72} opt/php72
    ln -s /bin usr/bin
    ln -s /bin usr/sbin
    ln -s /bin usr/local/bin
    mkdir tmp
    chmod 1777 tmp
  '';
}
