FROM debian:8

ENV DEBIAN_FRONTEND noninteractive

# Installing necessary packages
RUN echo 'Acquire::Check-Valid-Until "false";' >> /etc/apt/apt.conf && \
    echo "deb http://archive.debian.org/debian jessie contrib main non-free" > /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian-security jessie/updates main" >> /etc/apt/sources.list && \
    apt-get update && apt-get install -y --force-yes apt-utils && \
    apt-get install -y --force-yes \
    curl g++ bzip2 debhelper gcc rename make sudo wget expect gnupg perl-base perl \
    libc-bin libc6 libc6-dev build-essential dpkg-dev\
    cdbs devscripts equivs automake autoconf libtool libaudit-dev selinux-basics \
    libdb5.3 libdb5.3-dev libssl1.0.0 libssl-dev procps gawk libsigsegv2

RUN echo "deb-src http://archive.debian.org/debian jessie contrib main non-free" >> /etc/apt/sources.list && \
    apt-get update && apt-get build-dep python3 -y --force-yes

RUN curl -OL http://packages.bongosec.com/utils/gcc/gcc-9.4.0.tar.gz && \
    tar xzf gcc-9.4.0.tar.gz  && cd gcc-9.4.0/ && \
    ./contrib/download_prerequisites && \
    ./configure --prefix=/usr/local/gcc-9.4.0 --enable-languages=c,c++ --disable-multilib \
        --disable-libsanitizer && \
    make -j$(nproc) && make install && \
    ln -fs /usr/local/gcc-9.4.0/bin/g++ /usr/bin/c++ && cd / && rm -rf gcc-*

ENV CPLUS_INCLUDE_PATH "/usr/local/gcc-9.4.0/include/c++/9.4.0/"
ENV LD_LIBRARY_PATH "/usr/local/gcc-9.4.0/lib64:${LD_LIBRARY_PATH}"
ENV PATH "/usr/local/gcc-9.4.0/bin:${PATH}"

RUN curl -OL http://packages.bongosec.com/utils/cmake/cmake-3.18.3.tar.gz && \
    tar -zxf cmake-3.18.3.tar.gz && cd cmake-3.18.3 && \
    ./bootstrap --no-system-curl CXX=/usr/local/gcc-9.4.0/bin/g++ \
        CC=/usr/local/gcc-9.4.0/bin/gcc && \
    make -j$(nproc) && make install && ln -s /usr/local/bin/cmake /usr/bin/cmake && \
    cd / && rm -rf cmake-*

# Add the script to build the Debian package
ADD build.sh /usr/local/bin/build_package
RUN chmod +x /usr/local/bin/build_package

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/build_package"]
