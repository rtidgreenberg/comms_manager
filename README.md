# Overview 
Routing service for Comms/Platform/CCS Domain to manage traffic across systems.

All QOS files referenced are in comms_QOS_PROFILES.xml

The system has been separated into 3 domains:
- Platform Domain (Vehicle/Platform network)
- Comms Domain (Communications network)
- CCS Domain (CCS network)

## Directions
Default configs are set at the top of `routing_service_config_7.3.xml` within the `<configuration_variables>` tag section.

This is where you can modify the filters and Domain ID's.

This is also where you can enable/disable various routes using the config variables either in XML or by exporting as an ENV variable.

The routing service is setup so that you only need to modify these filter variables as needed to control the data going into the different domains.  

Modify the QOS across the COMMS domain as needed by referencing the `comms_qos_lib::topic_assign_qos`. This profile automatically assigns QOS per topic name.

See Included System Block Diagram for more info.

### Logging Versbosity
When running routing service pass in the args `-verbosity` and `-logFile` to log debug data as needed.

Reference [cmd-line-parameters](https://community.rti.com/static/documentation/connext-dds/7.3.0/doc/manuals/connext_dds_professional/services/routing_service/usage.html#routing-service-command-line-parameters) for more info.

# Changelog
## V10
- Rollback: Apply BZIP2 compression across all comms qos profiles
- Slow down Participant announcements
- Slow down heartbeats for discovery and user data

## V9
- Rollback: Add support for Command Message filtering based on destination.parentID GUID
- Remove Async Publisher from `periodic_1hz_best_effort_qos`
- Set `platform_qos` to use topic filters for GlobalPose and SpeedReport and for them to have time based filters of 1 second separation
- Rollback: Instance Resource Management
- Apply BZIP2 compression across all comms qos profiles

## V8
- Add support for Command Message filtering based on destination.parentID GUID
- Pulled in "latest" `ccs_qos` file
- Updated `ccs_qos` to propagate Type objects (This is only between the CCS Router and the CCS apps)
- Updated `ccs_qos` TTL to 2 (This is only between the CCS Router and the CCS apps)
- Updated `ccs_qos` to ASYNC type discovery publishing for large types
- Added instance resource management to `topic_assign_qos`

## V7
- Rollback:
	- Update discovery `initial_peers` for platform and ccs to only use loopback and shmem same as ccs
	- Set message_size_max to 1450. By making max message size < MTU it shifts fragmentation  
	off of the IP stack and onto the DDS side.  
	Will increase cpu usage but circumvents dropped IP fragment issues.
	- Increased `receive_pool`: `buffer_size` to 65k so you could still receive large samples from other Participants.

## V6
- Update discovery `initial_peers` for platform and ccs to only use loopback and shmem same as ccs
- Optimized participant discovery for comms_qos (smaller messages)
- Added register all comms types as a fallback for type propagation
- Increased participant_liveliness_assert_period to 120 secs (This could be lengthened further)
	- i.e. send out heartbeat every 2 minutes
- Increased participant_liveliness_lease_duration to 600 sec
	- i.e. required time between heartbeats
- Increased max_liveliness_loss_detection_period to 300 secs
	- i.e. check every 5 minutes if heartbeat is still good
- Set message_size_max to 1450. By making max message size < MTU it shifts fragmentation  
	off of the IP stack and onto the DDS side.  
	Will increase cpu usage but circumvents dropped IP fragment issues.
- Increased `receive_pool`: `buffer_size` to 65k so you could still receive large samples from other Participants.
- Set KEEP_LAST = 100 for Periodic data to increase send buffer
	(Suspect it was the one giving you the "make_sample_reclaimable" error when it overwrote old samples)
- Set output log file to `router_dbg` in the same folder. Change verbosity in `xml_logging_control` qos profile
- Consolidate both Platform to Platform routes into one for now/simplicity. Use `P2P_ENABLE` to enable.

## V5
- Converted separate _STAT and _CMD filters to a single one
- Added automatic QOS assignment using topic_filters in `topic_assign_qos`
- Added directions to readme
- Moved participant_qos profiles into ccs_qos and platform_qos
- Removed exclusive ownership qos in ccs_qos
- Uncommented register_types section to ensure type objects registered as backup
- Updated readme to reflect changes
- Updated diagram to reflect changes
- Moved back to single domain_route to allow register_types tags for the comms participant

## V4
- Added sessions for CTOA/Formation Platform to Platform routes
- Created C++ RemoteAdmin app
	- Added support for Group name update with RemoteAdmin
	- Added support for CTOA/Formation Route enable with RemoteAdmin
- Updated block diagram with increased detail/clarity
- Optimized Remote Admin Service
	- Added DEBUG_MODE variable that enables distributed logger and monitoring service entities
	- Added Remote Admin QOS to comms_qos_lib and updated routing service config
- Set default GROUP_ID to *
- Optimized Routing Service
	- Split configs into 2 separate domain_routes to optimize domain participant creation per CCS and Platform- (no extra entities)
	- Resolved large type discovery issues
	- 	Increased the discovery type size config(type_object_max_serialized_length) for some of the larger types (*Will require QOS update on Platform/CCS*)
	- 	Made Discovery writers asynchronous in Platform/CCS so we can get large types (*Will require QOS update on Platform/CCS*)
	- Removed the type registration
		- Routing service can pick up types across the *route* so no need to register types even if propagation is disabled.
- Updated sim components participant qos to point to comms_qos_lib participant_qos
- Added `xml_logging_control` to comms_qos_lib to allow for XML control of logging

## V3
- Updated to comms 6.0
- Included all comms 6.0 XML files using top level `include_all.xml` file
- Included all comms Types/Topics in `base.xml` file for future convenience in extensibility of sim components
- Updated test scripts to validate expected amount of topics received
- TriggerAddCommand type removed- Not in comms 6
- Created `start_router` script to simplify test scenarios
- Updated scripts to use `NDDS_QOS_PROFILES` etc. env variables to simplify vs cmd line args

## V2
- Updated Python Sim scripts
- Added Python comms controller remote Admin script
- Added Publisher/Subscriber partitions to limit Platform to Platform comms
- Added Domain Participant partitions using GROUP_ID's to segment Platforms and CCS as needed dynamically
- Made the MM* filters the default


# Design Constraints
- Cannot change the data model (comms version is "frozen" for this year(2024))
- Cannot extend the data model (issues with different vendors handling of extensibility)

# Requirements
- Platforms must be able to receive selected data from CCS [Platform to CCS filtering](#platform-to-ccs-filtering)
- CCS must be able to receive selected data from Platforms [CCS to Platform filtering](#ccs-to-platform-filtering)
- Platforms must not receive any data coming from other Platforms in default state [Platforms to Platforms isolation](#platforms-to-platforms-isolation)
- Must be able to dynamically enable session routes for topics between platforms [Dynamically enable platform routes](#dynamically-enable-platform-routes)
- Must be able to dynamically isolate user/discovery data between squad groups of Platforms [Dynamic grouping](#dynamic-grouping)
- CCS must be able to communicate with all Platforms by default regardless of Platform group [Dynamic grouping](#dynamic-grouping)
- Commands addressed with a destination.parentID GUID need to be filtered out appropriately


# Topics
## Platform to CCS Topics (Total 13)


## CCS to Platform Topics (Total 11)


## Platform to Platform topics (Add as needed)



# Unit Tests
## Platform to CCS filtering
Use the configuration variable `PLATFORM_TO_CCS_FILTER` in `routing_service_config_7.3.xml`
to modify the desired topics allowed to go from the CCS to the Platform.

### Test:
Create Platform Subscriber and CCS Publisher with defaults to simulate both systems.
- run CCS publisher on default domain
	- `./start_sim.sh ccs pub`
- run Platform subscriber on default domain
	- `./start_sim.sh platform sub`
- run routing service for Platform on default domain
	- `./start_router.sh platform USV-1`
- run routing service for CCS on default domain
	- `./start_router.sh ccs A-UOC1`

#### Pass criteria 1 :
Platform subscriber *SHOULD* be receiving messages.

#### Pass criteria 2 :
Terminal output will verify if topic qty received is equal to amount expected 

#### Summary:
Creating a Platform Subscriber sim and a CCS Publisher sim as well as the associated routing services tests the ability to route traffic between both hosts/routing services.


## CCS to Platform filtering 
Use the configuration variable `CCS_TO_PLATFORM_FILTER` in `routing_service_config_7.3.xml`
to modify the desired topics allowed to go from the Platform to the CCS.

### Test:
Create Platform Publisher and CCS Subscriber with defaults to simulate both systems
- run Platform Publisher on default domain
	- `./start_sim.sh platform pub`
- run CCS Subscriber on default domain
	- `./start_sim.sh ccs sub`
- run routing service for Platform on default domain
	- `./start_router.sh platform USV-1`
- run routing service for CCS on default domain
	- `./start_router.sh ccs A-UOC1`

#### Pass criteria 1:
CCS subscriber *SHOULD* be receiving messages.

#### Pass criteria 2 :
Terminal output will verify if topic qty received is equal to amount expected 

#### Summary:
Creating a Platform Publisher sim and a CCS Subscriber sim as well as the associated routing services tests the ability to route traffic between both hosts/routing services.


## Platforms to Platforms isolation
- Use Publisher/Subscriber partitions for Topic group, 
	- set Platform Subscribers Partition to "CCS"
	- set Platform Publishers Partition to "PLATFORM" 
	- set CCS Subscribers Partition to "PLATFORM"
	- set CCS Publishers Partition to "CCS"

### Test:
Create Platform publisher and Platform subscriber on different domains to simulate 2 different Platforms with network isolation.
- run USV-1 sim publisher on domain 5
	- `./start_sim.sh platform pub 5`
- run USV-2 sim subscriber on domain 6
	- `./start_sim.sh platform sub 6`
- run routing service for USV-1 domain 5
	- `./start_router.sh platform USV-1 5`
- run routing service for USV-2 domain 6
	- `./start_router.sh platform USV-2 6`

#### Pass criteria:
USV-2 Domain 6 subscriber *SHOULD NOT* be receiving any messages.

#### Summary:
Creating 2 different platform sims with different domain ID's simulates the network isolation in a deployed environment. 
By using Publisher/Subscriber partitions we can select our input data sources at a group level (Platforms/CCS)


## Dynamically enable platform routes
- Use Routing Service sessions to define Topics desired to bridge between platforms.
	- Reference the `platform_to_platform_session` defined in the `routing_service_config_7.3.xml` file
- Use the PLATFORM_TO_PLATFORM_FILTER or to define the desired topics per requirements.
	- Located in the `configuration_variables` section of `routing_service_config_7.3.xml` 
- Remotely enable either session as needed using Remote Admin Service


### Test:
Create Platform a publisher and a Platform subscriber on different domains to simulate 2 different Platforms with network isolation.
- run USV-1 sim publisher on domain 5
	- `./start_sim.sh platform pub 5`
- run USV-2 sim subscriber on domain 6
	- `./start_sim.sh platform sub 6`
- run routing service for USV-1 domain 5
	- `./start_router.sh platform USV-1 5`
- run routing service for USV-2 domain 6
	- `./start_router.sh platform USV-2 6`

At this time USV-2 Domain 6 subscriber *SHOULD NOT* be receiving any messages per the previous test.

Begin to enable session routes as desired. Use `--help` for supported args.

```
./remote_admin/build/RemoteAdmin --file ./UMAA_QOS_PROFILES.xml --resource USV-1 --p2p_enable
```

#### Pass criteria 1:
You should see just the `ContactReportType` Topic being received on USV-2

Disable the P2P route.
```
./remote_admin/build/RemoteAdmin --file ./UMAA_QOS_PROFILES.xml --resource USV-1 --p2p_disable
```

#### Pass criteria 2:
You should NOT see the `ContactReportType` Topic being received on USV-2

#### Summary:
Creating specific session routes as needed and controlling them with the remote admin interface allows us to control data flow between Platforms.

## Dynamic grouping
- Use Participant Partitions to isolate user data/discovery traffic between platforms into GROUPS
- Use Remote Admin controls interface to dynamically assign groups
- Verify after Platform group change CCS can still communicate
- Verify Platform to Platform comms are segmented by group

NOTE: We are using unique Domain ID's below for the Platform and CCS publishers/subscribers to segment them at the network layer within a VM. In a deployed environment they will be physically separated and can use the same DOMAIN ID

### Test:

Start a Platform publisher on Domain 6
```
./start_sim.sh platform pub 6
```
Start a Platform Router on Domain 6 for USV-6
```
./start_router.sh platform USV-6 6
```

Verify on Admin Console that you see USV-6 publishing data on it's Domain(6)
Verify on Admin Console that you see USV-6 publishing data on the Comms Domain(2)

Start a Platform Subscriber on Domain 7
```
./start_sim.sh platform sub 7
```

Start a Platform Router on Domain 7 for USV-7
```
./start_router.sh platform USV-7 7
```

Verify with Admin Console that you see USV-6 and USV-7 publishing data on their Domains ( 6 and 7 )
Verify with Admin Console on the COMMS Domain (2)  that you can see USV-6 and USV-7


Enable the P2P route on USV-6
```
./remote_admin/build/RemoteAdmin --file ./UMAA_QOS_PROFILES.xml --resource USV-6 --p2p_enable
```
#### Pass criteria 1:
You *SHOULD NOT* see any data coming across into USV-7 as it's route hasn't been enabled yet.

Enable the P2P route on USV-7
```
./remote_admin/build/RemoteAdmin --file ./UMAA_QOS_PROFILES.xml --resource USV-7 --p2p_enable
```

#### Pass criteria 2:
You *SHOULD* still receive ContactReportType on USV-7 subscriber


Change the group ID for USV-7 to group 3
```
./remote_admin/build/RemoteAdmin --file ./UMAA_QOS_PROFILES.xml --resource USV-7 --group 3
```

#### Pass criteria 3:
You *SHOULD NOT* still receive ContactReportType on USV-7 subscriber
- Groups are set to the wildcard * by default so as USV-7 is 3 and USV-6 is * they will still match

Change the group ID for USV-6 to group 3
```
./remote_admin/build/RemoteAdmin --file ./UMAA_QOS_PROFILES.xml --resource USV-6 --group 3
```
Restart platform 7 subscriber and verify you can still receive ContactReportType on USV-7 subscriber
- Both USV's will be in GROUP 3 (Verify in Admin Console in the Domain 2 logical view, click on the DP, and look at the entity info)

Start up a CCS subscriber on domain 8
```
./start_sim.sh ccs sub 8
```

Start a CCS Router on Domain 8 for A-UOC8
```
./start_router.sh ccs A-UOC8 8
```

#### Pass criteria 4:
You *SHOULD* still receive messages on A-UOC8 subscriber
- Both USV's will be in GROUP 3 (Verify in Admin Console in the Domain 2 logical view, click on the DP, and look at the entity info) and the CCS will be in the default partition of *


Change the group ID for USV-6 to group 1
```
./remote_admin/build/RemoteAdmin --file ./UMAA_QOS_PROFILES.xml --resource USV-6 --group 1
```

Restart platform 7 subscriber

#### Pass criteria 5:
You *SHOULD NOT* be able to receive ContactReportType on USV-7 subscriber
USV-6 will be in Group 1 and USV-7 will still be in Group 3 (Verify in Admin Console in the Domain 2 logical view, click on the DP, and look at the entity info)

Restart CCS domain 8 subscriber 

#### Pass criteria 6:
You *SHOULD* be receiving topics from USV-6 on the CCS subscriber
USV-6 will now be in Group 1 so we are verifying that after changing the Group Partition the CCS will still be able to receive data.

Change the group ID for USV-6 back to group 3
```
./remote_admin/build/RemoteAdmin --file ./UMAA_QOS_PROFILES.xml --resource USV-6 --group 3
```

#### Pass criteria 7:
You *SHOULD* be receiving ContactReportType on USV-7 subscriber
Both USV's will be back in GROUP 3 (Verify in Admin Console in the Domain 2 logical view, click on the DP, and look at the entity info)


Disable the P2P route on USV-7
```
./remote_admin/build/RemoteAdmin --file ./comms_QOS_PROFILES.xml --resource USV-7 --p2p_disable
```

Restart USV-7 subscriber(Platform subscriber domain 7)

#### Pass criteria 8:
You *SHOULD NOT* be receiving any topics on USV-7 subscriber 


#### Summary:
Creating Domain Participant Partitions and controlling them with the remote admin interface allows us to control traffic/segment discovery between Groups of Platforms and possibly CCS systems in the future to scale.

We are only changing the Domain Participant Partition for the Domain Participant on the Comms domain i.e. the `Comms Participant` in the Routing Service. The Domain Participants that are "internal" i.e. the ones that talk to the internal Platform or CCS topics are not changed.


## Command Content Filtering
- Use Content Filtered topics to filter commands addressed to the desired Platform GUID using the destination.parentID field.

### Test 1:
Create a Platform subscriber and a CCS publisher on default domains
- run Platform sim subscriber
	- `./start_sim.sh platform sub`
- run CCS sim publisher
	- `./start_sim.sh ccs pub`
- run routing service for Platform USV-1
	- `./start_router.sh platform USV-1`
- run routing service for CCS UOC-1 
	- `./start_router.sh ccs UOC-1 `

#### Pass criteria 1:
USV-1 subscriber *SHOULD* be receiving all 11 topics.

### Test 2:

Modify the GUID value in `./python_sim/ccs_pub.py` to be different.

Create a Platform subscriber and a CCS publisher on default domains
- run Platform sim subscriber
	- `./start_sim.sh platform sub`
- run CCS sim publisher
	- `./start_sim.sh ccs pub`
- run routing service for Platform USV-1
	- `./start_router.sh platform USV-1`
- run routing service for CCS UOC-1 
	- `./start_router.sh ccs UOC-1 `

#### Pass criteria 2:
USV-1 subscriber *SHOULD* only be receiving 10 topics.

USV-1 subscriber *SHOULD NOT* be receiving `MissionPlanObjectiveAddCommandType`.

#### Summary:
By using the PLATFORM_GUID value in a content filter we are able to deny messages being sent to Platforms who don't have matching GUIDs.


#### Use: 
Set the variable PLATFORM_GUID to the desired GUID in hex format without dashes.

Set the variable CCS_TO_PLATFORM_FILTER_GUID with the desired command topics that are uniquely addressed and contain the field `destination.parentID`

Set the variable CCS_TO_PLATFORM_FILTER with the rest of the topics that are being sent globally from the CCS to Platforms.

Set the correlating Platform GUID as desired in the `destination.parentID` field.