
FROM ubuntu:18.04 AS builder

#Install build tools.
RUN apt-get update -y && \
    apt-get install -y --fix-missing --no-install-recommends git ca-certificates cmake build-essential

#Install dev versions of MapServer dependencies.
RUN apt-get install -y --fix-missing --no-install-recommends libfreetype6-dev libjpeg8-dev libxml2-dev libproj-dev libgdal-dev

#Clone MapServer repository and checkout release branch.
WORKDIR /build
RUN git clone --branch rel-7-4-1 --single-branch https://github.com/mapserver/mapserver.git mapserver

#Build MapServer.
WORKDIR /build/mapserver/build
RUN cmake \
-DCMAKE_INSTALL_PREFIX=/build/install \
-DCMAKE_BUILD_TYPE=Release \
-DWITH_PROJ=ON \
-DWITH_PROTOBUFC=OFF \
-DWITH_KML=OFF \
-DWITH_SOS=OFF \
-DWITH_WMS=ON \
-DWITH_FRIBIDI=OFF \
-DWITH_HARFBUZZ=OFF \
-DWITH_ICONV=OFF \
-DWITH_CAIRO=OFF \
-DWITH_SVGCAIRO=OFF \
-DWITH_RSVG=OFF \
-DWITH_MYSQL=OFF \
-DWITH_FCGI=OFF \
-DWITH_GEOS=OFF \
-DWITH_POSTGIS=OFF \
-DWITH_GDAL=ON \
-DWITH_OGR=ON \
-DWITH_CLIENT_WMS=OFF \
-DWITH_CLIENT_WFS=OFF \
-DWITH_CURL=OFF \
-DWITH_WFS=ON \
-DWITH_WCS=ON \
-DWITH_LIBXML2=ON \
-DWITH_THREAD_SAFETY=ON \
-DWITH_GIF=OFF \
-DWITH_PYTHON=OFF \
-DWITH_PHP=OFF \
-DWITH_PHPNG=OFF \
-DWITH_PERL=OFF \
-DWITH_RUBY=OFF \
-DWITH_JAVA=OFF \
-DWITH_CSHARP=OFF \
-DWITH_POINT_Z_M=OFF \
-DWITH_ORACLESPATIAL=OFF \
-DWITH_ORACLE_PLUGIN=OFF \
-DWITH_MSSQL2008=OFF \
.. \
&& make 

RUN make install

FROM ubuntu:18.04

#Install MapServer dependencies.
RUN apt-get update -y && \
apt-get install -y --fix-missing --no-install-recommends libfreetype6 libjpeg8 libxml2 libproj12 libgdal20

#Copy build artifacts (TODO: probably only bin is nedded)
COPY --from=builder  /build/install/bin/ /usr/local/bin/
COPY --from=builder  /build/install/lib/ /usr/local/lib/
COPY --from=builder  /build/install/include/ /usr/local/include/
COPY --from=builder  /build/install/share/ /usr/local/share


#TODO clean this mess.
RUN apt-get install -y --fix-missing --no-install-recommends apache2
RUN ldconfig
RUN a2enmod cgid
RUN ln -s /usr/local/bin/mapserv /usr/lib/cgi-bin/mapserv
RUN chmod o+x /usr/local/bin/mapserv
RUN chmod 755 /usr/lib/cgi-bin
EXPOSE  80
ENV HOST_IP `ifconfig | grep inet | grep Mask:255.255.255.0 | cut -d ' ' -f 12 | cut -d ':' -f 2`
RUN apache2ctl start
CMD apache2ctl -D FOREGROUND


