FROM ubuntu:20.04

RUN DEBIAN_FRONTEND="noninteractive" apt-get update && apt-get -y install tzdata

RUN apt-get -y install build-essential \
    git \
    gperf \
    libgmp-dev \
    cmake \
    bison \
    curl \
    flex \
    gcc-multilib \
    linux-libc-dev \
    libboost-all-dev \
    libtinfo-dev \
    ninja-build \
    python3-setuptools \
    unzip \
    wget \
    python3-pip \
    python3 \
    openjdk-8-jre \
    tar \
    ccache \
    gdb

RUN mkdir /ESBMC_Project 
WORKDIR /ESBMC_Project 

# LLVM and clang
RUN wget https://github.com/llvm/llvm-project/releases/download/llvmorg-11.0.0/clang+llvm-11.0.0-x86_64-linux-gnu-ubuntu-20.04.tar.xz
RUN tar xJf clang+llvm-11.0.0-x86_64-linux-gnu-ubuntu-20.04.tar.xz && mv clang+llvm-11.0.0-x86_64-linux-gnu-ubuntu-20.04 clang11

# solvers
  # Boolector
  RUN git clone --depth=1 --branch=3.2.1 https://github.com/boolector/boolector \
    && cd boolector \
    && ./contrib/setup-lingeling.sh \
    && ./contrib/setup-btor2tools.sh \
    && ./configure.sh --prefix $PWD/../boolector-release \
    && cd build \
    && make -j8 \
    && make install 
    
  # CVC4
  RUN pip3 install toml 
  RUN git clone https://github.com/CVC4/CVC4.git \
    && cd CVC4 && git reset --hard b826fc8ae95fc \
    && ./contrib/get-antlr-3.4 \
    && ./configure.sh --optimized --prefix=../cvc4 --static --no-static-binary \
    && cd build && make -j8 \
    && make install 

  # Mathsat
  RUN wget http://mathsat.fbk.eu/download.php?file=mathsat-5.5.4-linux-x86_64.tar.gz -O mathsat.tar.gz \
    && tar xf mathsat.tar.gz \
    && mv mathsat-5.5.4-linux-x86_64 mathsat

  # GMP
  RUN wget https://gmplib.org/download/gmp/gmp-6.1.2.tar.xz \
    && tar xf gmp-6.1.2.tar.xz \
    && rm gmp-6.1.2.tar.xz \
    && cd gmp-6.1.2 \
    && ./configure --prefix $PWD/../gmp --disable-shared ABI=64 CFLAGS=-fPIC CPPFLAGS=-DPIC \
    && make -j8 \
    && make install 

  # Yices
  RUN git clone https://github.com/SRI-CSL/yices2.git && cd yices2 && git checkout Yices-2.6.1 && autoreconf -fi && ./configure --prefix $PWD/../yices --with-static-gmp=$PWD/../gmp/lib/libgmp.a && make -j9 && make static-lib && make install && cp ./build/x86_64-pc-linux-gnu-release/static_lib/libyices.a ../yices/lib && cd ..

  # z3
  RUN wget https://github.com/Z3Prover/z3/releases/download/z3-4.8.9/z3-4.8.9-x64-ubuntu-16.04.zip && unzip z3-4.8.9-x64-ubuntu-16.04.zip && mv z3-4.8.9-x64-ubuntu-16.04 z3

  # bitwuzla
  RUN git clone --depth=1 --branch=smtcomp-2021 https://github.com/bitwuzla/bitwuzla.git && cd bitwuzla && ./contrib/setup-lingeling.sh && ./contrib/setup-btor2tools.sh && ./contrib/setup-symfpu.sh && ./configure.sh --prefix $PWD/../bitwuzla-release && cd build && cmake -DGMP_INCLUDE_DIR=$PWD/../../gmp/include -DGMP_LIBRARIES=$PWD/../../gmp/lib/libgmp.a -DONLY_LINGELING=ON ../ && make -j8 && make install && cd .. && cd ..

  # ibex
  RUN ln /usr/bin/python3 /usr/bin/python
  RUN wget http://www.ibex-lib.org/ibex-2.8.9.tgz && tar xvfz ibex-2.8.9.tgz && cd ibex-2.8.9 && ./waf configure --lp-lib=soplex && ./waf install

# clean up
RUN rm mathsat.tar.gz \
  clang+llvm-11.0.0-x86_64-linux-gnu-ubuntu-20.04.tar.xz \
  ibex-2.8.9.tgz \
  z3-4.8.9-x64-ubuntu-16.04.zip

RUN apt-get install -y gdb


#ENV ESBMC_Project_cmake=".. -GNinja -DBUILD_TESTING=On -DENABLE_REGRESSION=On -DClang_DIR=/ESBMC_Project/clang11 -DLLVM_DIR=/ESBMC_Project/clang11 -DBUILD_STATIC=On -DBoolector_DIR=/ESBMC_Project/boolector-release -DZ3_DIR=/ESBMC_Project/z3 -DENABLE_MATHSAT=ON -DMathsat_DIR=/ESBMC_Project/mathsat -DENABLE_YICES=On -DYices_DIR=/ESBMC_Project/yices -DCVC4_DIR=/ESBMC_Project/cvc4 -DGMP_DIR=/ESBMC_Project/gmp -DBitwuzla_DIR=/ESBMC_Project/bitwuzla-release -DCMAKE_INSTALL_PREFIX:PATH=/ESBMC_Project/release"
# RUN ( \
#      echo 'LogLevel DEBUG2'; \
#      echo 'PermitRootLogin yes'; \
#      echo 'PasswordAuthentication yes'; \
#      echo 'Subsystem sftp /usr/lib/openssh/sftp-server'; \
#    ) > /etc/ssh/sshd_config_test_clion \
#    && mkdir /run/sshd


# CMD ["/usr/sbin/sshd", "-D", "-e", "-f", "/etc/ssh/sshd_config_test_clion"] 