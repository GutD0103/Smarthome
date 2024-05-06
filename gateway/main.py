import numpy as np
import time

#import my module

from mqtt import MyMQTTClient
from uart import UARTCommunication


AIO_USERNAME = "GutD"
AIO_KEY = "aio_HfJT236l1hBdOaGxjsUEbl5B7uXI"
AIO_FEED_ID = ["temperature", "humidity","ac","fan","light","tv"]


mqtt_client = MyMQTTClient(AIO_USERNAME, AIO_KEY, AIO_FEED_ID)
uart = UARTCommunication(baudrate=115200, timeout=1)


def myProcessData(data):
    data = data.replace("!", "")
    data = data.replace("#", "")
    splitData = data.split(":")
    print(splitData)
    if splitData[0] == "TEMP":
        mqtt_client.publish_data("temperature",splitData[1])
    elif splitData[0] == "LUX":
        mqtt_client.publish_data("lux",splitData[1])
    elif splitData[0] == "HUMI":
        mqtt_client.publish_data("humidity",splitData[1])
    else:
        print("we dont have that measurement to publish")
    
def myProcessMess(feed_id, payload):
    if feed_id == "fan":
        if payload == "0":
            uart.send_data("FAN OFF\n")
        elif payload == "1":
            uart.send_data("FAN ON\n")
    elif feed_id == "ac":
        if payload == "0":
            uart.send_data("AC OFF\n")
        elif payload == "1":
            uart.send_data("AC ON\n")
    elif feed_id == "light":
        if payload == "0":
            uart.send_data("LIGHT OFF\n")
        elif payload == "1":
            uart.send_data("LIGHT ON\n")
    elif feed_id == "tv":
        if payload == "0":
            uart.send_data("TV OFF\n")
        elif payload == "1":
            uart.send_data("TV ON\n")
def main():

    # serial init
    uart.processData = myProcessData
    mqtt_client.processMessage = myProcessMess
    #mqtt init
    mqtt_client.start()

    while True:
        uart.read_serial()
        time.sleep(1)
    
if __name__ == "__main__":
    main()


