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

class C2Sim:
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

      # Create DataWriters/DataReaders with the specified QoS profiles
      self.comms_cmd_writer = dds.DynamicData.DataWriter(
          self.comms_cmd_topic,
          self.qos_provider.datawriter_qos_from_profile(args.qos_profile)
      )
      self.comms_cmd_ack_reader = dds.DynamicData.DataReader(
          self.comms_cmd_ack_topic,
          self.qos_provider.datareader_qos_from_profile(args.qos_profile)
      )
      self.comms_status_reader = dds.DynamicData.DataReader(
          self.comms_status_topic,
          self.qos_provider.datareader_qos_from_profile(args.qos_profile)
      )

    async def read_status_data(self):
      print("Waiting for Status data")
      async for data in self.comms_status_reader.take_data_async():
        print(f'- Received Status data with Session ID: {data["msg.session_id[1]"]}')
       

    async def read_cmd_ack_data(self):
      print("Waiting for CommandAck data")
      async for data in self.comms_cmd_ack_reader.take_data_async():
        print(f'- Received CommandAck data with Session ID: {data["msg.session_id[1]"]}')

    async def write_comms_cmd(self):
      # Create sample
      comms_cmd_sample = dds.DynamicData(self.comms_cmd_type)

      # Set Source GUID
      source_guid = uuid.UUID(str(args.src_guid))
      source_guid_list = list(source_guid.bytes)
      comms_cmd_sample["msg.source"] = source_guid_list

      # Set Destination GUID
      dest_guid = uuid.UUID(str(args.dest_guid))
      dest_guid_list = list(dest_guid.bytes)
      comms_cmd_sample["msg.destination"] = dest_guid_list

      # Set Session "GUID"
      session_guid = [args.session_id for d in range(16)]
      comms_cmd_sample["msg.session_id"] = session_guid

      # Create sim "Payload"
      payload = [random.randrange(0, 10, 2) for d in range(16)]
      comms_cmd_sample["msg.payload"] = payload

      while True:
          self.comms_cmd_writer.write(comms_cmd_sample)
          print("Writing to CommsCommand topic")
          await asyncio.sleep(1)


    async def run(self) -> None:
        await asyncio.gather(
            self.write_comms_cmd(),
            self.read_status_data(),
            self.read_status_data()
            )




if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="C2 Sim"
    )
    print("\n\nRUNNING C2 SIM\n\n")
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
      rti.asyncio.run(C2Sim(args).run())
        
    except KeyboardInterrupt:
        pass


