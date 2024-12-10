/*
 * (c) 2021 Copyright, Real-Time Innovations, Inc.  All rights reserved.
 *
 * RTI grants Licensee a license to use, modify, compile, and create derivative
 * works of the Software.  Licensee has the right to distribute object form
 * only for use with RTI products.  The Software is provided "as is", with no
 * warranty of any type, including any warranty for fitness for any purpose.
 * RTI is under no obligation to maintain or support the Software.  RTI shall
 * not be liable for any incidental or consequential damages arising out of the
 * use or inability to use the software.
 */

#include "ServiceAdmin.hpp"
#include "ServiceCommon.hpp"
#include "rti/request/RequesterParams.hpp"
#include "rti/request/Requester.hpp"

#include "application.hpp" // Argument parsing

#include <chrono>
#include <thread>

// using namespace rti::request;
using namespace application;


using namespace dds::core;
using namespace RTI::Service;
using namespace RTI::Service::Admin;

static constexpr unsigned int WAIT_TIMEOUT_SEC_MAX = 10;

static void send_route_update(
        rti::request::Requester<
                RTI::Service::Admin::CommandRequest,
                RTI::Service::Admin::CommandReply> &requester,
                ApplicationArguments args)
{

    try
    {
        /*
         * Setup command
         */
        CommandRequest request;
        std::string route = "";
           

        std::string full_resource_id = "/routing_services/" + args.resource + "/domain_routes/platform/sessions/platform_to_platform_session/state";
        std::string application_name = args.resource;

        // Build Message
        request.action(CommandActionKind::UPDATE_ACTION);
        request.resource_identifier(full_resource_id);
        request.application_name(application_name);

        std::cout << "Sending Remote Admin ROUTE UPDATE: \n"
                     "Updating Route: " << route << "\n"                 
                     "resource_id: " << full_resource_id << "\n"
                     "application_name: " << application_name << std::endl;

        if (args.p2p)
        {
            // Sets state to Enabled
            dds::topic::topic_type_support<EntityState>::to_cdr_buffer(
                reinterpret_cast<std::vector<char> &>(request.octet_body()),
                EntityState(EntityStateKind::ENABLED));
                std::cout << "Enabling State" << std:: endl;
        }
        else
        {
            // Sets state to Enabled
            dds::topic::topic_type_support<EntityState>::to_cdr_buffer(
                reinterpret_cast<std::vector<char> &>(request.octet_body()),
                EntityState(EntityStateKind::DISABLED));
            std::cout << "Disabling State" << std::endl;
        }

        /*
         * Send Message
         */
        requester.send_request(request);
        CommandReply reply =
            requester.receive_replies(Duration(WAIT_TIMEOUT_SEC_MAX))[0];
        if (reply.retcode() == CommandReplyRetcode::OK_RETCODE)
        {
            std::cout << "Command returned: " << reply.string_body() << std::endl;
        }
        else
        {
            std::cout << "Unsuccessful command returned value " << reply.retcode()
                      << "." << std::endl;
            throw dds::core::Error("Error in replier");
        }
    }
    catch(const std::exception& ex)
    {
        std::cout << "Exception: " << ex.what() << std::endl;
        return;
    }
    
}

static void send_group_update(
    rti::request::Requester<
        RTI::Service::Admin::CommandRequest,
        RTI::Service::Admin::CommandReply> &requester,
    ApplicationArguments args)
{

    try
    {
        /*
         * Setup command
         */
        CommandRequest request;

        // Hardcoded for a Platform resource type right now, can add arg to switch up /domain_routes/ccs/ if need to change CCS group
        std::string full_resource_id = "/routing_services/" + args.resource + "/domain_routes/platform/participants/comms_participant";
        std::string string_body = "str://\"<participant><domain_participant_qos><partition><name><element>";
        string_body += args.group; 
        string_body += "</element></name></partition></domain_participant_qos></participant>\"";
        std::string application_name = args.resource;

        std::cout << "Sending Remote GROUP UPDATE: \n"
                     "resource_id: " << full_resource_id << "\n"
                     "body_text: " << string_body << "\n"
                     "application_name: " << application_name << std::endl;

        // Build Message
        request.action(CommandActionKind::UPDATE_ACTION);
        request.string_body(string_body);
        request.resource_identifier(full_resource_id);
        request.application_name(application_name);

        // Send Message
        requester.send_request(request);
        CommandReply reply =
            requester.receive_replies(Duration(WAIT_TIMEOUT_SEC_MAX))[0];
        if (reply.retcode() == CommandReplyRetcode::OK_RETCODE)
        {
            std::cout << "Command returned: " << reply.string_body() << std::endl;
        }
        else
        {
            std::cout << "Unsuccessful command returned value " << reply.retcode()
                      << "." << std::endl;
            throw dds::core::Error("Error in replier");
        }
    }
    catch (const std::exception &ex)
    {
        std::cout << "Exception: " << ex.what() << std::endl;
        return;
    }
}

int main(int argc, char *argv[])
{
    try {

        // Parse arguments and handle control-C
        auto arguments = parse_arguments(argc, argv);
        if (arguments.parse_result == ParseReturn::exit)
        {
            return EXIT_SUCCESS;
        }
        else if (arguments.parse_result == ParseReturn::failure)
        {
            return EXIT_FAILURE;
        }
        setup_signal_handlers();

        // Retrieve QoS from custom profile XML
        dds::core::QosProvider qos_provider(arguments.config);

        // Create a DomainParticipant with the custom QOS
        dds::domain::DomainParticipant participant(arguments.domain_id);

        // create requester params
        rti::request::RequesterParams requester_params(participant);
        requester_params.request_topic_name(COMMAND_REQUEST_TOPIC_NAME);
        requester_params.reply_topic_name(COMMAND_REPLY_TOPIC_NAME);

        // Set QOS
        requester_params.datareader_qos(qos_provider.datareader_qos("umaa_qos_lib::remote_admin_requester_qos"));
        requester_params.datawriter_qos(qos_provider.datawriter_qos("umaa_qos_lib::remote_admin_requester_qos"));

        rti::request::Requester<
                RTI::Service::Admin::CommandRequest,
                RTI::Service::Admin::CommandReply>
                requester(requester_params);

        // Wait for Routing Service Discovery
        dds::core::status::PublicationMatchedStatus matched_status;
        unsigned int wait_count = 0;

        std::cout << "Waiting for a matching replier..." << std::endl;
        while (matched_status.current_count() < 1
               && wait_count < WAIT_TIMEOUT_SEC_MAX) {
            matched_status =
                    requester.request_datawriter().publication_matched_status();
            wait_count++;
            std::this_thread::sleep_for(std::chrono::seconds(1));
        }

        if (matched_status.current_count() < 1) {
            throw dds::core::Error("No matching replier found.");
        }


        if (arguments.update_p2p)
        {
            send_route_update(requester, arguments);
        }
            

        if (arguments.update_group)
            send_group_update(requester, arguments);
    } catch (const std::exception &ex) {
        std::cout << "Exception: " << ex.what() << std::endl;
        return -1;
    }

    return 0;
}
