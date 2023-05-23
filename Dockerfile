FROM amazoncorretto:17-alpine3.17 AS prepare

RUN addgroup -S gradle && adduser -G gradle -S gradle --disabled-password
USER gradle

WORKDIR /workspace/api

ARG VERSION=
COPY ./src src
COPY ./gradle gradle
COPY ./build.gradle .
COPY ./gradlew .

RUN sh ./gradlew clean bootjar
RUN mkdir -p ./build/libs/extracted
RUN java -Djarmode=layertools -jar ./build/libs/*.jar extract --destination ./build/libs/extracted

FROM amazoncorretto:17-alpine3.17 AS production
VOLUME /tmp
ARG EXTRACTED=/workspace/api/build/libs/extracted
COPY --from=prepare ${EXTRACTED}/dependencies/ ./
COPY --from=prepare ${EXTRACTED}/spring-boot-loader/ ./
COPY --from=prepare ${EXTRACTED}/snapshot-dependencies/ ./
COPY --from=prepare ${EXTRACTED}/application/ ./
ENTRYPOINT ["java","org.springframework.boot.loader.JarLauncher"]