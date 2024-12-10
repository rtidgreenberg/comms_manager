/*
 * (c) Copyright, Real-Time Innovations, 2024.  All rights reserved.
 * RTI grants Licensee a license to use, modify, compile, and create derivative
 * works of the software solely for use with RTI Connext DDS. Licensee may
 * redistribute copies of the software provided that all such copies are subject
 * to this license. The software is provided "as is", with no warranty of any
 * type, including any warranty for fitness for any purpose. RTI is under no
 * obligation to maintain or support the software. RTI shall not be liable for
 * any incidental or consequential damages arising out of the use or inability
 * to use the software.
 */

#ifndef APPLICATION_HPP
#define APPLICATION_HPP

#include <iostream>
#include <csignal>
#include <dds/core/ddscore.hpp>


namespace application {

// Catch control-C and tell application to shut down
bool shutdown_requested = false;

static constexpr unsigned int ADMIN_DOMAIN_ID = 100;

inline void stop_handler(int)
{
    shutdown_requested = true;
    std::cout << "preparing to shut down..." << std::endl;

}

inline void setup_signal_handlers()
{
    signal(SIGINT, stop_handler);
    signal(SIGTERM, stop_handler);
}

enum class ParseReturn {
    ok,
    failure,
    exit
};

struct ApplicationArguments {
    ParseReturn parse_result;

    std::string config;
    int domain_id = 0;

    std::string resource = "";
    std::string group = "";

    bool p2p = false;

    bool update_group = false;
    bool update_p2p = false;

};

// Parses application arguments for example.
inline ApplicationArguments parse_arguments(int argc, char *argv[])
{
    int arg_processing = 1;
    bool show_usage = false;
    
    ApplicationArguments args;

    // set default
    args.domain_id = ADMIN_DOMAIN_ID;

    while (arg_processing < argc) {
        if ((argc > arg_processing + 1) && (strcmp(argv[arg_processing], "-d") == 0 || strcmp(argv[arg_processing], "--domain") == 0))
        {
            args.domain_id = atoi(argv[arg_processing + 1]);
            arg_processing += 2;
        }
        else if ((argc > arg_processing + 1) && (strcmp(argv[arg_processing], "-f") == 0 || strcmp(argv[arg_processing], "--file") == 0))
        {
            args.config = argv[arg_processing + 1];
            arg_processing += 2;
        }
        else if ((argc > arg_processing + 1) && (strcmp(argv[arg_processing], "-r") == 0 || strcmp(argv[arg_processing], "--resource") == 0))
        {
            args.resource = argv[arg_processing + 1];
            arg_processing += 2;
        }
        else if ((argc > arg_processing + 1) && (strcmp(argv[arg_processing], "-g") == 0 || strcmp(argv[arg_processing], "--group") == 0))
        {
            args.group = argv[arg_processing + 1];
            args.update_group = true;
            arg_processing += 2;
        }
        else if ((argc > arg_processing) && (strcmp(argv[arg_processing], "--p2p_enable") == 0))
        {
            args.p2p = true;
            args.update_p2p = true;
            arg_processing += 1;
        }
        else if ((argc > arg_processing) && strcmp(argv[arg_processing], "--p2p_disable") == 0)
        {
            args.p2p = false;
            args.update_p2p = true;
            arg_processing += 1;
        }
        else if (strcmp(argv[arg_processing], "-h") == 0 || strcmp(argv[arg_processing], "--help") == 0)
        {
            std::cout << "Remote Admin Service Controller." << std::endl;
            show_usage = true;
            args.parse_result = ParseReturn::exit;
            break;
        }
        else
        {
            std::cout << "Bad parameter." << std::endl;
            show_usage = true;
            args.parse_result = ParseReturn::failure;
            break;
        }
    }
    if (show_usage)
    {
        std::cout << "Usage:\n"
                     "   -d, --domain     <int>             Domain ID \n"
                     "   -f, --file       <string>          QOS Config File\n"
                     "   -r, --resource   <string>          Resource Identifier i.e. 'USV-1' \n"
                     "                                      REQUIRED\n"
                     "   -g, --group      <int>             Group ID to assign resource to \n"
                     "Only applicable to Platforms: \n"
                     "   --p2p_enable           <bool>     Enable Platform to Platform topic routes.\n"
                     "   --p2p_disable           <bool>    Disable Platform to Platform topic routes.\n"

                  << std::endl;
    }

    return args;
}

}  // namespace application

#endif  // APPLICATION_HPP
