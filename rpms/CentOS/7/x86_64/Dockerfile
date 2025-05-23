FROM centos:7

# Install all the necessary tools to build the packages
RUN yum install -y gcc make wget git \
    openssh-clients sudo gnupg file-devel\
    automake autoconf libtool policycoreutils-python \
    yum-utils system-rpm-config rpm-devel \
    gettext nspr nspr-devel \
    nss nss-devel libdb libdb-devel \
    zlib zlib-devel rpm-build bison \
    sharutils bzip2-devel xz-devel lzo-devel \
    e2fsprogs-devel libacl-devel libattr-devel \
    openssl-devel libxml2-devel kexec-tools elfutils \
    libcurl-devel elfutils-libelf-devel \
    elfutils-libelf elfutils-devel libgcrypt-devel \
    libarchive-devel libarchive bluez-libs-devel bzip2 \
    desktop-file-utils expat-devel findutils gcc-c++ gdbm-devel \
    glibc-devel gmp-devel gnupg2 libappstream-glib \
    libffi-devel libtirpc-devel libGL-devel libuuid-devel \
    libX11-devel ncurses-devel pkgconfig readline-devel \
    redhat-rpm-config sqlite-devel gdb tar tcl-devel tix-devel tk-devel \
    valgrind-devel python-rpm-macros python3

    # Install Perl 5.10
RUN curl -OL http://packages.bongosec.com/utils/perl/perl-5.10.1.tar.gz && \
    gunzip perl-5.10.1.tar.gz && tar -xf perl*.tar && \
    cd /perl-5.10.1 && ./Configure -des -Dcc='gcc' -Dusethreads && \
    make -j2 && make install && ln -fs /usr/local/bin/perl /bin/perl && \
    cd / && rm -rf /perl-5.10.1*

# Update rpmbuild, rpm and autoconf
RUN curl -O http://packages.bongosec.com/utils/autoconf/autoconf-2.69.tar.gz && \
    gunzip autoconf-2.69.tar.gz && tar xvf autoconf-2.69.tar && \
    cd autoconf-2.69 && ./configure && make -j$(nproc) && \
    make install && cd / && rm -rf autoconf-*

RUN curl -O http://packages.bongosec.com/utils/rpm/rpm-4.15.1.tar.bz2 && \
    tar -xjf rpm-4.15.1.tar.bz2 && cd rpm-4.15.1 && \
    ./configure --without-lua && make -j$(nproc) && make install && cd / && rm -rf rpm-*

RUN mkdir -p /usr/local/var/lib/rpm && \
    cp /var/lib/rpm/Packages /usr/local/var/lib/rpm/Packages && \
    /usr/local/bin/rpm --rebuilddb && rm -rf /root/rpmbuild

RUN curl -OL http://packages.bongosec.com/utils/gcc/gcc-9.4.0.tar.gz && \
    tar xzf gcc-9.4.0.tar.gz  && cd gcc-9.4.0/ && \
    ./contrib/download_prerequisites && \
    ./configure --prefix=/usr/local/gcc-9.4.0 --enable-languages=c,c++ \
        --disable-multilib --disable-libsanitizer && \
    make -j$(nproc) && make install && \
    ln -fs /usr/local/gcc-9.4.0/bin/g++ /usr/bin/c++ && \
    ln -fs /usr/local/gcc-9.4.0/bin/gcc /usr/bin/cc && cd / && rm -rf gcc-*

ENV CPLUS_INCLUDE_PATH "/usr/local/gcc-9.4.0/include/c++/9.4.0/"
ENV LD_LIBRARY_PATH "/usr/local/gcc-9.4.0/lib64/"
ENV PATH "/usr/local/gcc-9.4.0/bin:${PATH}"

RUN curl -OL http://packages.bongosec.com/utils/cmake/cmake-3.18.3.tar.gz && \
    tar -zxf cmake-3.18.3.tar.gz && cd cmake-3.18.3 && \
    ./bootstrap --no-system-curl CC=/usr/local/gcc-9.4.0/bin/gcc \
        CXX=/usr/local/gcc-9.4.0/bin/g++ && \
    make -j$(nproc) && make install && cd / && rm -rf cmake-*

# Add the scripts to build the RPM package
ADD build.sh /usr/local/bin/build_package
RUN chmod +x /usr/local/bin/build_package

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/build_package"]
