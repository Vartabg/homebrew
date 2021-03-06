require 'formula'

class Gnupg2 < Formula
  homepage 'http://www.gnupg.org/'
  url 'ftp://ftp.gnupg.org/gcrypt/gnupg/gnupg-2.0.22.tar.bz2'
  sha1 '9ba9ee288e9bf813e0f1e25cbe06b58d3072d8b8'

  option '8192', 'Build with support for private keys of up to 8192 bits'

  depends_on 'libgpg-error'
  depends_on 'libgcrypt'
  depends_on 'libksba'
  depends_on 'libassuan'
  depends_on 'pinentry'
  depends_on 'pth'
  depends_on 'gpg-agent'
  depends_on 'dirmngr' => :recommended
  depends_on 'libusb-compat' => :recommended
  depends_on 'readline' => :optional

  # Fix hardcoded runtime data location
  # upstream: http://git.gnupg.org/cgi-bin/gitweb.cgi?p=gnupg.git;h=c3f08dc
  # Adjust package name to fit our scheme of packaging both gnupg 1.x and
  # 2.x, and gpg-agent separately, and adjust tests to fit this scheme
  # Fix typo that breaks compilation:
  # http://lists.gnupg.org/pipermail/gnupg-users/2013-May/046652.html
  def patches; DATA; end

  def install
    inreplace 'g10/keygen.c', 'max=4096', 'max=8192' if build.include? '8192'

    (var/'run').mkpath

    ENV.append 'LDFLAGS', '-lresolv'

    ENV['gl_cv_absolute_stdint_h'] = "#{MacOS.sdk_path}/usr/include/stdint.h"

    agent = Formula["gpg-agent"].opt_prefix

    args = %W[
      --disable-dependency-tracking
      --prefix=#{prefix}
      --sbindir=#{bin}
      --enable-symcryptrun
      --disable-agent
      --with-agent-pgm=#{agent}/bin/gpg-agent
      --with-protect-tool-pgm=#{agent}/libexec/gpg-protect-tool
    ]

    if build.with? 'readline'
      args << "--with-readline=#{Formula["readline"].opt_prefix}"
    end

    system "./configure", *args
    system "make"
    system "make check"
    system "make install"

    # Conflicts with a manpage from the 1.x formula, and
    # gpg-zip isn't installed by this formula anyway
    rm man1/'gpg-zip.1'
  end
end

__END__
diff --git a/common/homedir.c b/common/homedir.c
index 4b03cfe..c84f26f 100644
--- a/common/homedir.c
+++ b/common/homedir.c
@@ -472,7 +472,7 @@ dirmngr_socket_name (void)
     }
   return name;
 #else /*!HAVE_W32_SYSTEM*/
-  return "/var/run/dirmngr/socket";
+  return "HOMEBREW_PREFIX/var/run/dirmngr/socket";
 #endif /*!HAVE_W32_SYSTEM*/
 }
 
diff --git a/configure b/configure
index e5479af..a17a54d 100755
--- a/configure
+++ b/configure
@@ -578,8 +578,8 @@ MFLAGS=
 MAKEFLAGS=
 
 # Identity of this package.
-PACKAGE_NAME='gnupg'
-PACKAGE_TARNAME='gnupg'
+PACKAGE_NAME='gnupg2'
+PACKAGE_TARNAME='gnupg2'
 PACKAGE_VERSION='2.0.22'
 PACKAGE_STRING='gnupg 2.0.22'
 PACKAGE_BUGREPORT='http://bugs.gnupg.org'
diff --git a/tests/openpgp/Makefile.in b/tests/openpgp/Makefile.in
index c9ceb2d..7044900 100644
--- a/tests/openpgp/Makefile.in
+++ b/tests/openpgp/Makefile.in
@@ -312,11 +312,11 @@ GPG_IMPORT = ../../g10/gpg2 --homedir . \
 
 
 # Programs required before we can run these tests.
-required_pgms = ../../g10/gpg2 ../../agent/gpg-agent \
+required_pgms = ../../g10/gpg2 \
                 ../../tools/gpg-connect-agent
 
 TESTS_ENVIRONMENT = GNUPGHOME=$(abs_builddir) GPG_AGENT_INFO= LC_ALL=C \
-		    ../../agent/gpg-agent --quiet --daemon sh
+		    gpg-agent --quiet --daemon sh
 
 TESTS = version.test mds.test \
 	decrypt.test decrypt-dsa.test \
