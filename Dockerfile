FROM ubuntu:20.04

ARG QT_MAJOR=5
ARG QT_MINOR=15
ARG QT_PATCH=3
ARG QT_MAJMIN=${QT_MAJOR}.${QT_MINOR}
ARG QT_VERSION=${QT_MAJMIN}.${QT_PATCH}
ARG QT_ARCHIVE="qt-everywhere-src-${QT_VERSION}"
ARG QT_ARCHIVE_NAME="qt-everywhere-opensource-src-${QT_VERSION}.tar.xz"
ARG QT_URL="https://download.qt.io/official_releases/qt/${QT_MAJMIN}/${QT_VERSION}/single/${QT_ARCHIVE_NAME}"
ARG QT_SHA256="b7412734698a87f4a0ae20751bab32b1b07fdc351476ad8e35328dbe10efdedb"
ARG QTIF_VERSION="4.3.0"
ARG QTIF_NAME="installer-framework"

# check this link for dependencies https://doc.qt.io/qt-5/linux-requirements.html
ARG QT_ESSENTIALS="build-essential perl python git"
ARG QT_COMMON="libfontconfig1-dev libfreetype6-dev libx11-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev libxcb1-dev libx11-xcb-dev libxcb-glx0-dev libxkbcommon-x11-dev libxcb-xfixes0-dev"
ARG QT_WEBENGINE="libssl-dev libxcursor-dev libxcomposite-dev libxdamage-dev libxrandr-dev libdbus-1-dev libfontconfig1-dev libcap-dev libxtst-dev libpulse-dev libudev-dev libpci-dev libnss3-dev libasound2-dev libxss-dev libegl1-mesa-dev gperf bison"
ARG QT_WEBKIT="flex bison gperf libicu-dev libxslt-dev ruby"
ARG QT_MULTIMEDIA="libasound2-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev"

ARG MXE_PKGS="autoconf automake autopoint bash bison bzip2 flex g++ g++-multilib gettext git gperf intltool libc6-dev-i386 libgdk-pixbuf2.0-dev libltdl-dev libssl-dev libtool-bin libxml-parser-perl lzip make openssl p7zip-full patch perl pkg-config python ruby sed unzip wget xz-utils"

WORKDIR /
USER root
ENV MXE_TARGETS="x86_64-w64-mingw32.shared"
ENV PATH=/mxe/usr/bin:$PATH
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt full-upgrade -y && apt-get autoremove -y && apt install --no-install-recommends -y wget libyaml-cpp-dev liblua5.3-0 locales lcov \
    ${QT_COMMON} \
    ${QT_ESSENTIALS} \
    ${QT_WEBENGINE} \
    ${QT_WEBKIT} \
    ${MXE_PKGS} \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*

# RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales
   
RUN echo "${QT_SHA256}  ${QT_ARCHIVE_NAME}" > sha.txt && \
	wget ${QT_URL} && \
	sha256sum -c sha.txt && \
	tar xf ${QT_ARCHIVE_NAME} && \
	cd ${QT_ARCHIVE} && \
	./configure -opensource -confirm-license -nomake examples -nomake tests && \
	make -j$(nproc) && \
	make install && \
	cd / && \
	rm -rf ${QT_ARCHIVE} && \
	rm ${QT_ARCHIVE_NAME} sha.txt

RUN git clone git://code.qt.io/${QTIF_NAME}/${QTIF_NAME}.git -b ${QTIF_VERSION} && cd ${QTIF_NAME} && /usr/local/Qt-${QT_VERSION}/bin/qmake && make -j$(nproc) && make install && cd .. && rm -rf ${QTIF_NAME}

RUN git clone https://github.com/mxe/mxe.git && cd mxe && make MXE_PLUGIN_DIRS='plugins/gcc9' MXE_TARGETS='x86_64-w64-mingw32.shared' -j$(nproc) JOBS=$(nproc) lua yaml-cpp qt5 && make clean-junk && make clean-pkg && rm /mxe/pkg/* && rm -r /mxe/.ccache && if [ -d "/mxe/log" ]; then rm -rf /mxe/log/*; fi

# RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales

