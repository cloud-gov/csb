# Use our hardened cloud-service-broker base image.
ARG base_image

# Builder: Build brokerpaks for use with cloud service broker.
FROM ${base_image} AS build
WORKDIR /app
ADD ./brokerpaks ./brokerpaks

ENV BUILD_ENV=development

# For local builds only, add the ZScaler CA certificate to the trust store so Docker
# can make HTTPS connections. `csb pak build` needs to do this to download binaries.
# Find your ZScaler cert with $(brew --prefix)/etc/ca-certificates/cert.pem.
# From https://help.zscaler.com/zia/adding-custom-certificate-application-specific-trust-store
ADD zscaler.crt /tmp/zscaler.crt
# Only copy Use BUILD_ENV variable within the container to copy the CA certificate into the certificate directory and update
RUN if [ "$BUILD_ENV" = "production" ] ; then echo "production env"; else echo \
"non-production env: $BUILD_ENV"; CERT_DIR=$(openssl version -d | cut -f2 -d \")/certs ; \
cp /tmp/zscaler.crt $CERT_DIR ; update-ca-certificates ; \
fi

RUN /app/csb pak build brokerpaks/empty

FROM ${base_image}

# Copy brokerpaks to final image
COPY --from=build /app/empty-1.0.0.brokerpak /app/
