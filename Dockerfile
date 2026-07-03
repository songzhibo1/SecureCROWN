FROM ubuntu:22.04

RUN apt-get update && apt install -y build-essential cmake libboost-system-dev libeigen3-dev git net-tools

WORKDIR /root

ADD . ./fss/

WORKDIR /root/fss

RUN rm -rf build && mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && cmake --build . --target benchmark-crown
