# (c) 2024 Copyright, Real-Time Innovations, Inc.  All rights reserved.
# RTI grants Licensee a license to use, modify, compile, and create derivative
# works of the Software.  Licensee has the right to distribute object form only
# for use with RTI products.  The Software is provided "as is", with no warranty
# of any type, including any warranty for fitness for any purpose. RTI is under
# no obligation to maintain or support the Software.  RTI shall not be liable for
# any incidental or consequential damages arising out of the use or inability to
# use the software.

import rti.connextdds as dds
from rti.types.builtin import String
import time
import argparse
import random
import threading
import rti.asyncio
import asyncio
import uuid

class Rx_tst:
    def __init__(self, args):

      # Load QoS/Types from XML files
      self.qos_provider = dds.QosProvider(args.files)

      # Create a Participant from specific QOS Profile
      self.participant = dds.DomainParticipant(
          args.domain_id, self.qos_provider.participant_qos_from_profile(
              args.qos_profile)
      )

      #Pull in DynamicData types
      self.comms_cmd_type = self.qos_provider.type("comms_cmd")
      self.comms_cmd_ack_type = self.qos_provider.type("comms_cmd_ack")
      self.comms_status_type = self.qos_provider.type("comms_status")

      # Create Topics and associate with types
      self.comms_cmd_topic = dds.DynamicData.Topic(
          self.participant,
          "CommsCommand",
          self.comms_cmd_type
      )
      self.comms_cmd_ack_topic = dds.DynamicData.Topic(
          self.participant,
          "CommsCommandAck",
          self.comms_cmd_ack_type
      )
      self.comms_status_topic = dds.DynamicData.Topic(
          self.participant,
          "CommsStatus",
          self.comms_status_type
      )

      # Create Some Listeners
      self.comms_cmd_reader = dds.DynamicData.DataReader(
          self.comms_cmd_topic,
          self.qos_provider.datareader_qos_from_profile(args.qos_profile)
      )
      self.comms_cmd_ack_reader = dds.DynamicData.DataReader(
          self.comms_cmd_ack_topic,
          self.qos_provider.datareader_qos_from_profile(args.qos_profile)
      )
      self.comms_status_reader = dds.DynamicData.DataReader(
          self.comms_status_topic,
          self.qos_provider.datareader_qos_from_profile(args.qos_profile)
      )

    def process_data(self,reader,data,info):
      if info.valid:
        # Access the writer's instance handle from the sample info
        writer_handle = info.publication_handle

        # Get the Participant Info for the matched DataWriter
        participant_data = reader.matched_publication_participant_data(
            writer_handle)
        
        # Print out first locator
        ip_list = participant_data.default_unicast_locators[0].address[-4:]
        address_str = '.'.join(
            str(byte) for byte in ip_list)
        domain_id = participant_data.domain_id

        # Get first port
        port = participant_data.default_unicast_locators[0].port

      # Get Topic Name
      topic_name = reader.topic_name

      # Get GUID's
      src_byte_array = data["msg.source"]
      src_uuid_from_list = uuid.UUID(bytes=bytes(src_byte_array))
      dest_byte_array = data["msg.destination"]
      dest_uuid_from_list = uuid.UUID(bytes=bytes(dest_byte_array))
      sess_byte_array = data["msg.session_id"]
      sess_uuid_from_list = uuid.UUID(bytes=bytes(sess_byte_array))

      # Print all
      print(f"""
            Received Topic: {topic_name}
            From: {participant_data.participant_name.name}
            IP: {address_str}
            Port: {port}
            Domain ID: {domain_id}
            Source GUID = {str(src_uuid_from_list)}
            Destination GUID = {str(dest_uuid_from_list)}
            Session GUID: {str(sess_uuid_from_list)}
            """)

    async def read_status_data(self):
      if args.type == "comms" or args.type == "c2":
        print("Waiting for Status data")
        async for data,info in self.comms_status_reader.take_async():
          self.process_data(self.comms_status_reader, data, info)

    async def read_cmd_ack_data(self):
      if args.type == "comms" or args.type == "c2":
        print("Waiting for CommandAck data")
        async for data,info in self.comms_cmd_ack_reader.take_async():
          self.process_data(self.comms_cmd_ack_reader,data,info)

    async def read_cmd_data(self):
      if args.type == "comms" or args.type == "platform":
        print("Waiting for Command data")
        async for data,info in self.comms_cmd_reader.take_async():
          self.process_data(self.comms_cmd_reader, data, info)


    async def run(self) -> None:
        await asyncio.gather(
            self.read_cmd_data(),
            self.read_status_data(),
            self.read_cmd_ack_data()
            )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Comms Manager Rx_tst"
    )
    print("\n\nComms Manager Rx_tst\n\n")
    parser.add_argument(
        "-f", "--files", type=str, default="", help="XML Config files"
    )
    parser.add_argument(
        "--src_guid", type=str, default=0, help="Source GUID"
    )
    parser.add_argument(
        "--dest_guid", type=str, default=0, help="Destination GUID"
    )
    parser.add_argument(
        "--qos_profile", type=str, default=0, help="QOS Profile"
    )
    parser.add_argument(
        "--session_id", type=int, default=0, help="Session ID"
    )
    parser.add_argument(
        "-d", "--domain_id", type=int, default=0, help="Domain ID"
    )
    parser.add_argument(
        "-v", "--verbosity", type=int, default=1, help="How much debugging output to show | Range: 0-3 | Default: 1",
    )
    parser.add_argument(
        "--type", type=str, default=0, help="Type"
    )

    args = parser.parse_args()

    verbosity_levels = {
        0: dds.Verbosity.SILENT,
        1: dds.Verbosity.EXCEPTION,
        2: dds.Verbosity.WARNING,
        3: dds.Verbosity.STATUS_ALL,
    }

    # Sets Connext verbosity to help debugging
    verbosity = verbosity_levels.get(args.verbosity, dds.Verbosity.EXCEPTION)

    dds.Logger.instance.verbosity = verbosity

    try:
      # Run
      rti.asyncio.run(Rx_tst(args).run())
        
    except KeyboardInterrupt:
        pass


