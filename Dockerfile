# Use our hardened cloud-service-broker base image.
ARG base_image

# Builder: Build brokerpaks for use with cloud service broker.
FROM ${base_image} AS build
ADD . /app
WORKDIR /app
RUN ls /
RUN ls /app

ARG BUILD_ENV=development

# For non-production builds only, add the ZScaler CA certificate to the trust store so Docker
# can make HTTPS connections. `csb pak build` needs to do this to download binaries.
# You must copy the ZScaler cert to ./zscaler.crt; the most reliable way is:
# `cp $(brew --prefix)/etc/ca-certificates/cert.pem ./zscaler.crt`.
# See: https://help.zscaler.com/zia/adding-custom-certificate-application-specific-trust-store
RUN set -e; if [ "$BUILD_ENV" = "production" ] ; then echo "production env"; else echo \
"non-production env: $BUILD_ENV"; CERT_DIR=$(openssl version -d | cut -f2 -d \")/certs ; \
cp /app/zscaler.crt $CERT_DIR ; update-ca-certificates ; \
fi

RUN /app/csb pak build brokerpaks/empty
RUN /app/csb pak build brokerpaks/aws-ses

RUN ls /
RUN ls /app

FROM ${base_image}

# Copy brokerpaks to final image
COPY --from=build /app/empty-0.0.1.brokerpak /app/
COPY --from=build /app/datagov-brokerpak-smtp-current.brokerpak /app/
