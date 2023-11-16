FROM adoptopenjdk/maven-openjdk11:latest AS builder

COPY src /usr/src/app/src
COPY pom.xml /usr/src/app

# COPY security/wakehealth-root-ca.crt /usr/local/share/ca-certificates/local-root-ca.crt
# RUN cat /usr/local/share/ca-certificates/local-root-ca.crt >> /etc/ssl/certs/ca-certificates.crt \
    # && update-ca-certificates

RUN openssl s_client -connect stackoverflow.com:443 -showcerts </dev/null 2>/dev/null | perl -0ne 'print if s|.*(-----BEGIN.*-----END.*?[\r\n]+).*|\1|gms' | tee "/usr/local/share/ca-certificates/nscacert.crt" >/dev/null \
    && openssl s_client -connect wakehealth.edu:443 -showcerts </dev/null 2>/dev/null | perl -0ne 'print if s|.*(-----BEGIN.*-----END.*?[\r\n]+).*|\1|gms' | tee "/usr/local/share/ca-certificates/wakehealth_root_ca.crt" >/dev/null \
    && update-ca-certificates; fi

RUN mvn -f /usr/src/app/pom.xml clean package -DskipTests -q -Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true

FROM eclipse-temurin:11

COPY --from=builder /usr/src/app/target/*.jar /usr/app/

COPY src/main/resources/* /usr/app/resources/

# ENTRYPOINT [ "/bin/bash" ]

# java -Xmx4096m -jar /usr/app/deid-3.0.26-dataflow.jar --deidConfigFile=/usr/app/resources/deid_config_omop_genrep.yaml --annotatorConfigFile=/usr/app/resources/annotator_config.yaml --inputType=local --inputResource=/data/temp_sample.json --phiFileName=/data/phi_person_data.csv --personFile=/data/phi_person_data.csv --outputResource=/output --textIdFields="NOTE_ID" --textInputFields="NOTE_TEXT"

ENTRYPOINT ["java", "-Xmx4096m", "-jar", "/usr/app/deid-3.0.26-dataflow.jar", "--deidConfigFile=/usr/app/resources/deid_config_omop_genrep.yaml", "--annotatorConfigFile=/usr/app/resources/annotator_config.yaml", "--inputType=local", "--inputResource=/data/batch.json", "--phiFileName=/data/phi_person_data.csv", "--personFile=/data/batch.json", "--outputResource=/output", "--textIdFields=NOTE_ID", "--textInputFields=NOTE_TEXT"]
