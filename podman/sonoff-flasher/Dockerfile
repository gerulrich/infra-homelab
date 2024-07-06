FROM python:3-alpine
WORKDIR /app
# taken from https://github.com/JelmerT/cc2538-bsl/blob/feature/ITead_Sonoff_Zigbee-delay/cc2538-bsl.py
COPY cc2538-bsl.py flash.sh /app/
RUN pip3 install intelhex pyserial
ENTRYPOINT ["/bin/sh", "/app/flash.sh"]