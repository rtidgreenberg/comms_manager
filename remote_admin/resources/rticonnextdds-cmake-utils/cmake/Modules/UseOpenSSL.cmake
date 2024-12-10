# (c) 2018 Copyright, Real-Time Innovations, Inc.  All rights reserved.
#
# RTI grants Licensee a license to use, modify, compile, and create derivative
# works of the software solely for use with RTI Connext DDS.  Licensee may
# redistribute copies of the software provided that all such copies are
# subject to this license. The software is provided "as is", with no warranty
# of any type, including any warranty for fitness for any purpose. RTI is
# under no obligation to maintain or support the software.  RTI shall not be
# liable for any incidental or consequential damages arising out of the use or
# inability to use the software.

#[[.rst:
.. _use_openssl:

UseOpenSSL
----------

This module contains functions to use OpenSSL like file certificate generation.


.. _connextdds_openssl_generate_selfsigned_ca:
.. _connextdds_openssl_generate_signed_ca:

Generate CA
^^^^^^^^^^^
::

    connextdds_openssl_generate_selfsigned_ca(
        OUTPUT_CERT_FILE file
        OUTPUT_KEY_FILE file
        CRL_NUMBER_FILE crlNumberFile
        [TEXT]
        [RSA_KEY_PASSWORD pass]
        [RSA_KEY_ENCRYPTION alg]
        [RSA_NUMBITS]
        [ECPARAM_NAME ec_name]
        [ECPARAM_OUTPUT_FILE ec_output]
        [EDPARAM_NAME ed_name]
        [DIGEST digestName]
        [DAYS num]
        [CA_EXTENSION ext]
        CONFIG_FILE file
        WORKING_DIRECTORY path
    )

Generates a Certificate Authority using a configuration file.

Arguments:

``OUTPUT_CERT_FILE`` (required)
    Output path for the certificate file.

``OUTPUT_KEY_FILE`` (required)
    Output path for the private key file.

``CRL_NUMBER_FILE`` (required)
    The file containing the current CRL number. Must match the crlnumber from
    the cnf file.

``TEXT`` (optional)
    Print the certificate in text format instead of base64.

``RSA_KEY_PASSWORD`` (optional)
    Password for the private RSA key.

``RSA_KEY_ENCRYPTION`` (optional)
    Algorithm to encrypt the password.

``RSA_NUMBITS`` (required with `RSA_KEY_PASSWORD`)
    Size in bits of the private key to generate.

``ECPARAM_OUTPUT_FILE`` (optional)
    Output file with the EC parameters.

``ECPARAM_NAME`` (required with `ECPARAM_OUTPUT_FILE`)
    Short name of the EC parameters.

``EDPARAM_NAME`` (optional)
    Short name of the EDDSA used.

``DIGEST`` (optional)
    Digest algorithm. For instance `SHA256`.

``CONFIG_FILE`` (required)
    Configuration file to generate the CA.

``DAYS`` (optional)
    The number of days the certificate will be valid.

``CA_EXTENSION`` (optional)
    Name of extension to apply from the CA configuration file.

``WORKING_DIRECTORY`` (required)
    The working directory for the openssl command. This is needed to resolve
    correctly the relative paths in the configuration file. It has to be set to
    the Certificate Authority's directory, i.e. the one containing the "ca"
    and "identities" folders. Examples are: "ecdsa01", or "rsa01".


.. _connextdds_openssl_generate_signed_certificate:

Generate Certificate
^^^^^^^^^^^^^^^^^^^^
::

    connextdds_openssl_generate_signed_certificate(
        [OUTPUT_PEM_FILE file]
        OUTPUT_CERT_FILE file
        OUTPUT_KEY_FILE file
        [TEXT]
        [RSA_KEY_PASSWORD]
        [RSA_KEY_ENCRYPTION]
        [RSA_NUMBITS]
        [ECPARAM_NAME ec_name]
        [ECPARAM_OUTPUT_FILE ec_output]
        [EDPARAM_NAME ed_name]
        [PHRASE_PASSWORD pass]
        [PRIVATE_KEY_PASSWORD pass]
        [PRIVATE_KEY_ENCRYPTION pass_encrypt]
        CONFIG_FILE file
        CA_CONFIG_FILE file
        CA_CERT_FILE file
        CA_KEY_FILE file
        CA_KEY_PASSWORD pass
        DAYS num
        [CA_EXTENSION ext]
        WORKING_DIRECTORY path
    )

Generates a certificate and signs with the CA.

Arguments:

``OUTPUT_PEM_FILE`` (optional)
    The output PEM file combining the private key and the certificate.

``OUTPUT_CERT_FILE`` (required)
    The output path for the signed certificate file.

``OUTPUT_KEY_FILE`` (required)
    The output path for the private key.

``TEXT`` (optional)
    Print the certificate in text format in addition to base64.

``RSA_KEY_PASSWORD`` (optional)
    Password for the private RSA key.

``RSA_KEY_ENCRYPTION`` (optional)
    Algorithm to encrypt the password. Possible values are: `DES3`.

``RSA_NUMBITS`` (required with `RSA_KEY_PASSWORD`)
    Size in bits of the private key to generate.

``ECPARAM_OUTPUT_FILE`` (optional)
    Output file with the EC parameters.

``ECPARAM_NAME`` (required with `ECPARAM_OUTPUT_FILE`)
    Short name of the EC parameters.

``EDPARAM_NAME`` (optional)
    Short name of the EDDSA used.

``CONFIG_FILE`` (required)
    The configuration file to generate the certificate.

``CA_CONFIG_FILE`` (required)
    CA configuration file.

``CA_CERT_FILE`` (required)
    CA certificate file for verifying the certificate.

``CA_KEY_FILE`` (required)
    CA private key file for signing the certificate.

``CA_KEY_PASSWORD`` (required)
    CA private key password.

``DAYS`` (required)
    The number of days the certificate will be valid.

``CA_EXTENSION`` (optional)
    Name of extension to apply from the CA configuration file.

``WORKING_DIRECTORY`` (required)
    The working directory for the openssl command. This is needed to resolve
    correctly the relative paths in the configuration file. It has to be set to
    the Certificate Authority's directory, i.e. the one containing the "ca"
    and "identities" folders. Examples are: "ecdsa01", or "rsa01".

#]]

include(FindRTIOpenSSL)

# For this module we only need the openssl executable
if(NOT OPENSSL_EXECUTABLE)
    message("OpenSSL executable not found. Make "
        "sure the variable OPENSSL_EXECUTABLE is properly defined. If you use "
        "an external OpenSSL intallation, make sure you ran "
        "find_package(RTIOpenSSL [version]) before including this file. In "
        "case you are using a builtin openssl shipped with the toolchain, make "
        "sure you have set OPENSSL_EXECUTABLE in the ProjectOptions file for "
        "your architecture."
    )
endif()

# Get the command for openssl
connextdds_get_library_search_path_definition(
    OUTPUT lib_search_def
    DIRECTORIES
        ${OPENSSL_HOST_PATH_ENV}
)
set(OPENSSL_COMMAND
    ${CMAKE_COMMAND} -E env
        ${lib_search_def}
        OPENSSL_CONF=${OPENSSL_DEFAULT_CONFIG_FILE}
    ${OPENSSL_EXECUTABLE}
)

set(CONNEXTDDS_RESOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/../..")

function(connextdds_openssl_generate_rsa_key)
    set(options "")
    set(single_args OUTPUT_KEY_FILE PASSWORD KEY_ENCRYPTION NUMBITS)
    set(multi_args "")
    cmake_parse_arguments(_OPENSSL "${options}" "${single_args}" "${multi_args}" ${ARGN})
    connextdds_check_required_arguments(_OPENSSL_OUTPUT_KEY_FILE _OPENSSL_NUMBITS)

    # Get the directory for creation.
    get_filename_component(key_dir "${_OPENSSL_OUTPUT_KEY_FILE}" DIRECTORY)

    # Optional args
    set(rsa_encryption_arg)
    if(_OPENSSL_KEY_ENCRYPTION)
        string(TOLOWER ${_OPENSSL_KEY_ENCRYPTION} encryption)
        set(rsa_encryption_arg "-${encryption}")
    endif()
    if(_OPENSSL_PASSWORD)
        list(APPEND rsa_encryption_arg "-passout" "pass:${_OPENSSL_PASSWORD}")
    endif()

    add_custom_command(
        COMMENT "Generating RSA key: ${_OPENSSL_OUTPUT_KEY_FILE}"
        OUTPUT "${_OPENSSL_OUTPUT_KEY_FILE}"
        COMMAND
            ${CMAKE_COMMAND} -E make_directory ${key_dir}
        COMMAND
            ${OPENSSL_COMMAND} genrsa
                ${rsa_encryption_arg}
                -out ${_OPENSSL_OUTPUT_KEY_FILE}
                ${_OPENSSL_NUMBITS}
        VERBATIM
    )
endfunction()

function(connextdds_openssl_generate_ec_params)
    set(options "")
    set(single_args OUTPUT_FILE NAME)
    set(multi_args "")
    cmake_parse_arguments(_OPENSSL "${options}" "${single_args}" "${multi_args}" ${ARGN})
    connextdds_check_required_arguments(_OPENSSL_OUTPUT_FILE _OPENSSL_NAME)

    # Get the directory for creation.
    get_filename_component(out_dir "${_OPENSSL_OUTPUT_FILE}" DIRECTORY)

    add_custom_command(
        VERBATIM
        COMMENT "Generating EC params: ${_OPENSSL_OUTPUT_FILE}"
        OUTPUT "${_OPENSSL_OUTPUT_FILE}"
        COMMAND
            ${CMAKE_COMMAND} -E make_directory ${out_dir}
        COMMAND
            ${OPENSSL_COMMAND} ecparam
                -name ${_OPENSSL_NAME}
                -out ${_OPENSSL_OUTPUT_FILE}
    )
endfunction()

function(connextdds_openssl_generate_private_key)
    set(options "")
    set(single_args
        OUTPUT_KEY_FILE PASSWORD KEY_ENCRYPTION
        ECPARAM_OUTPUT_FILE ECPARAM_NAME
    )
    set(multi_args "")
    cmake_parse_arguments(_OPENSSL "${options}" "${single_args}" "${multi_args}" ${ARGN})
    connextdds_check_required_arguments(
        _OPENSSL_OUTPUT_KEY_FILE _OPENSSL_PASSWORD _OPENSSL_KEY_ENCRYPTION
    )

    # Get the directory for creation.
    get_filename_component(out_dir "${_OPENSSL_OUTPUT_KEY_FILE}" DIRECTORY)

    set(additional_deps)
    set(additional_args)
    if(_OPENSSL_ECPARAM_OUTPUT_FILE)
        connextdds_openssl_generate_ec_params(
            OUTPUT_FILE ${_OPENSSL_ECPARAM_OUTPUT_FILE}
            NAME ${_OPENSSL_ECPARAM_NAME}
        )

        list(APPEND additional_deps ${_OPENSSL_ECPARAM_OUTPUT_FILE})
        list(APPEND additional_args -paramfile ${_OPENSSL_ECPARAM_OUTPUT_FILE})
    endif()

    string(TOLOWER ${_OPENSSL_KEY_ENCRYPTION} encrypt_arg)
    set(encrypt_arg "-${encrypt_arg}")

    add_custom_command(
        VERBATIM
        COMMENT "Generating private key: ${_OPENSSL_OUTPUT_KEY_FILE}"
        OUTPUT
            ${_OPENSSL_OUTPUT_KEY_FILE}
        COMMAND
            ${CMAKE_COMMAND} -E make_directory ${out_dir}
        COMMAND
            ${OPENSSL_COMMAND} genpkey
                ${encrypt_arg}
                -pass pass:${_OPENSSL_PASSWORD}
                ${additional_args}
                -out ${_OPENSSL_OUTPUT_KEY_FILE}
        DEPENDS
            ${additional_deps}
    )
endfunction()

# This macro returns a 20Bytes hexadecimal serial number that can be used with
# OpenSSL.
macro(get_serial_number)
    set(options "")
    set(single_args BASE_NAME)
    set(multi_args "")
    cmake_parse_arguments(SERIAL
        "${options}"
        "${single_args}"
        "${multi_args}" ${ARGN}
    )
    connextdds_check_required_arguments(SERIAL_BASE_NAME)

    string(RANDOM
        LENGTH 40
        ALPHABET 0123456789ABCDEF
        _${SERIAL_BASE_NAME}_serial_number)
endmacro()

function(connextdds_openssl_generate_selfsigned_ca)
    set(options TEXT)
    set(single_args
        OUTPUT_KEY_FILE OUTPUT_CERT_FILE CONFIG_FILE DIGEST DAYS CRL_NUMBER_FILE
        RSA_KEY_PASSWORD RSA_KEY_ENCRYPTION RSA_NUMBITS
        ECPARAM_NAME ECPARAM_OUTPUT_FILE
        EDPARAM_NAME
        CA_EXTENSION
        WORKING_DIRECTORY
    )
    set(multi_args "")
    cmake_parse_arguments(_OPENSSL "${options}" "${single_args}" "${multi_args}" ${ARGN})
    connextdds_check_required_arguments(
        _OPENSSL_OUTPUT_KEY_FILE _OPENSSL_OUTPUT_CERT_FILE
        _OPENSSL_CONFIG_FILE _OPENSSL_CRL_NUMBER_FILE
        _OPENSSL_WORKING_DIRECTORY
    )

    # Get the directories to create them
    get_filename_component(cert_dir "${_OPENSSL_OUTPUT_CERT_FILE}" DIRECTORY)
    get_filename_component(key_dir "${_OPENSSL_OUTPUT_KEY_FILE}" DIRECTORY)

    # Optional args
    set(optional_args)
    if(_OPENSSL_DAYS)
        list(APPEND optional_args -days ${_OPENSSL_DAYS})
    endif()
    if(_OPENSSL_DIGEST)
        string(TOLOWER ${_OPENSSL_DIGEST} digest)
        list(APPEND optional_args "-${digest}")
    endif()
    if(_OPENSSL_TEXT)
        list(APPEND optional_args "-text")
    endif()
    if(_OPENSSL_CA_EXTENSION)
        list(APPEND optional_args -extensions ${_OPENSSL_CA_EXTENSION})
    endif()

    if(_OPENSSL_RSA_KEY_PASSWORD)
        connextdds_openssl_generate_rsa_key(
            OUTPUT_KEY_FILE "${_OPENSSL_OUTPUT_KEY_FILE}"
            PASSWORD ${_OPENSSL_RSA_KEY_PASSWORD}
            KEY_ENCRYPTION ${_OPENSSL_RSA_KEY_ENCRYPTION}
            NUMBITS ${_OPENSSL_RSA_NUMBITS}
        )

        # If we generate a RSA key, the key file is a dependency, not an output
        set(ca_key_arg -new -key "${_OPENSSL_OUTPUT_KEY_FILE}")
        set(ca_key_dep "${_OPENSSL_OUTPUT_KEY_FILE}")
        set(ca_key_output)
    elseif(_OPENSSL_ECPARAM_OUTPUT_FILE)
        connextdds_openssl_generate_ec_params(
            OUTPUT_FILE "${_OPENSSL_ECPARAM_OUTPUT_FILE}"
            NAME ${_OPENSSL_ECPARAM_NAME}
        )

        # We add the param as a dependency and the key as output
        set(ca_key_arg
            -newkey "ec:${_OPENSSL_ECPARAM_OUTPUT_FILE}"
            -keyout "${_OPENSSL_OUTPUT_KEY_FILE}"
        )
        set(ca_key_dep "${_OPENSSL_ECPARAM_OUTPUT_FILE}")
        set(ca_key_output "${_OPENSSL_OUTPUT_KEY_FILE}")
    elseif(_OPENSSL_EDPARAM_NAME)
        set(ca_key_arg -newkey "${_OPENSSL_EDPARAM_NAME}" -keyout "${_OPENSSL_OUTPUT_KEY_FILE}")
        set(ca_key_dep)
        set(ca_key_output "${_OPENSSL_OUTPUT_KEY_FILE}")
    else()
        # If we want to autocreate a key, the key file is an output, not a dependency
        set(ca_key_arg -newkey rsa:2048 -keyout "${_OPENSSL_OUTPUT_KEY_FILE}")
        set(ca_key_dep)
        set(ca_key_output "${_OPENSSL_OUTPUT_KEY_FILE}")
    endif()

    add_custom_command(
        VERBATIM
        COMMENT "Generating self-signed CA: ${_OPENSSL_OUTPUT_CERT_FILE}"
        OUTPUT
            ${_OPENSSL_OUTPUT_CERT_FILE}
            ${ca_key_output}
        COMMAND
            ${CMAKE_COMMAND} -E make_directory
                ${cert_dir} ${key_dir} ${_OPENSSL_WORKING_DIRECTORY}
                ${_OPENSSL_WORKING_DIRECTORY}/ca/database
        COMMAND
            # We can't use the WORKING_DIRECTORY argument since the directory is
            # created in the first command and we don't want to create the dir
            # from CMake since if it's removed, it won't be created unless CMake
            # is called again.
            ${CMAKE_COMMAND} -E chdir ${_OPENSSL_WORKING_DIRECTORY}
            ${OPENSSL_COMMAND} req
                -nodes -x509 ${optional_args} ${ca_key_arg}
                -config ${_OPENSSL_CONFIG_FILE}
                -out ${_OPENSSL_OUTPUT_CERT_FILE}
        COMMAND
            ${CMAKE_COMMAND} -DCONTENT=01 -DOUTPUT=${_OPENSSL_CRL_NUMBER_FILE}
                -P ${CONNEXTDDS_RESOURCE_DIR}/cmake/Scripts/WriteFile.cmake
        DEPENDS
            ${ca_key_dep}
            ${_OPENSSL_CONFIG_FILE}
    )
endfunction()

function(connextdds_openssl_generate_signed_certificate)
    set(options INCLUDE_CA_CERT TEXT RSA_PSS_PADDING)
    set(single_value_args
        OUTPUT_CERT_FILE OUTPUT_KEY_FILE
        CONFIG_FILE DAYS WORKING_DIRECTORY
        RSA_KEY_PASSWORD RSA_KEY_ENCRYPTION RSA_NUMBITS
        ECPARAM_NAME ECPARAM_OUTPUT_FILE
        EDPARAM_NAME
        PHRASE_PASSWORD
        PRIVATE_KEY_PASSWORD PRIVATE_KEY_ENCRYPTION
        CA_KEY_FILE CA_CONFIG_FILE CA_CERT_FILE CA_KEY_PASSWORD CA_EXTENSION
        DIGEST
    )
    set(multi_value_args "")
    cmake_parse_arguments(_OPENSSL
        "${options}"
        "${single_value_args}"
        "${multi_value_args}"
        ${ARGN})
    connextdds_check_required_arguments(
        _OPENSSL_OUTPUT_CERT_FILE
        _OPENSSL_OUTPUT_KEY_FILE
        _OPENSSL_CONFIG_FILE _OPENSSL_DAYS _OPENSSL_WORKING_DIRECTORY
        _OPENSSL_CA_KEY_FILE _OPENSSL_CA_CONFIG_FILE _OPENSSL_CA_CERT_FILE
    )

    # The cert request file is just the cert file but with an appended suffix.
    # We don't care much about the name because we will end up deleting the file
    # at the end of this function.
    set(certRequestFile "${_OPENSSL_OUTPUT_CERT_FILE}TemporaryRequestFile")

    # Get the directory to create temporal files
    get_filename_component(cert_dir "${_OPENSSL_OUTPUT_CERT_FILE}" DIRECTORY)
    get_filename_component(key_dir "${_OPENSSL_OUTPUT_KEY_FILE}" DIRECTORY)

    # Optional arguments

    set(text_arg)
    if(_OPENSSL_TEXT)
        set(text_arg -text)
    endif()

    set(digest_arg)
    if(_OPENSSL_DIGEST)
        set(digest_arg "-${_OPENSSL_DIGEST}")
    endif()

    set(ca_extension)
    if(_OPENSSL_CA_EXTENSION)
        set(ca_extension "-extensions" ${_OPENSSL_CA_EXTENSION})
    endif()

    set(ca_password_arg)
    if(_OPENSSL_CA_KEY_PASSWORD)
        set(ca_password_arg -passin "pass:${_OPENSSL_CA_KEY_PASSWORD}")
    endif()

    set(req_password)
    if(_OPENSSL_PHRASE_PASSWORD)
        set(req_password -passout "pass:${_OPENSSL_PHRASE_PASSWORD}")
    else()
        # "nodes" means that openssl won't encrypt the private key
        set(req_password -nodes)
    endif()

    set(append_ca_files)
    if(_OPENSSL_INCLUDE_CA_CERT)
        set(append_ca_files "${_OPENSSL_CA_CERT_FILE}")
    endif()

    # We can create a private key with or without password
    if(_OPENSSL_PRIVATE_KEY_PASSWORD)
        connextdds_openssl_generate_private_key(
            OUTPUT_KEY_FILE "${_OPENSSL_OUTPUT_KEY_FILE}"
            PASSWORD ${_OPENSSL_PRIVATE_KEY_PASSWORD}
            KEY_ENCRYPTION ${_OPENSSL_PRIVATE_KEY_ENCRYPTION}
            ECPARAM_OUTPUT_FILE "${_OPENSSL_ECPARAM_OUTPUT_FILE}"
            ECPARAM_NAME ${_OPENSSL_ECPARAM_NAME}
        )

        # We add the key as a dependency and the key as output
        set(key_arg
            -key "${_OPENSSL_OUTPUT_KEY_FILE}"
            -passin "pass:${_OPENSSL_PRIVATE_KEY_PASSWORD}"
        )
        set(key_dep ${_OPENSSL_OUTPUT_KEY_FILE} ${_OPENSSL_ECPARAM_OUTPUT_FILE})
        set(key_output)
    elseif(_OPENSSL_RSA_KEY_PASSWORD)
        connextdds_openssl_generate_rsa_key(
            OUTPUT_KEY_FILE "${_OPENSSL_OUTPUT_KEY_FILE}"
            PASSWORD "${_OPENSSL_RSA_KEY_PASSWORD}"
            KEY_ENCRYPTION ${_OPENSSL_RSA_KEY_ENCRYPTION}
            NUMBITS ${_OPENSSL_RSA_NUMBITS}
        )

        # If we generate a RSA key, the file is a dependency, not an output
        set(key_arg -passin pass:${_OPENSSL_RSA_KEY_PASSWORD} -key "${_OPENSSL_OUTPUT_KEY_FILE}")
        set(key_dep "${_OPENSSL_OUTPUT_KEY_FILE}")
        set(key_output)
    elseif(_OPENSSL_ECPARAM_OUTPUT_FILE)
        connextdds_openssl_generate_ec_params(
            NAME ${_OPENSSL_ECPARAM_NAME}
            OUTPUT_FILE "${_OPENSSL_ECPARAM_OUTPUT_FILE}"
        )

        # We add the param as a dependency and the key as output
        set(key_arg
            -newkey "ec:${_OPENSSL_ECPARAM_OUTPUT_FILE}"
            -keyout "${_OPENSSL_OUTPUT_KEY_FILE}"
        )
        set(key_dep "${_OPENSSL_ECPARAM_OUTPUT_FILE}")
        set(key_output "${_OPENSSL_OUTPUT_KEY_FILE}")
    elseif(_OPENSSL_EDPARAM_NAME)
        set(key_arg -newkey "${_OPENSSL_EDPARAM_NAME}" -keyout "${_OPENSSL_OUTPUT_KEY_FILE}")
        set(key_dep)
        set(key_output "${_OPENSSL_OUTPUT_KEY_FILE}")
    else()
        # If we want to autocreate a key, the file is an output, not a dependency
        set(key_dep)
        set(key_output "${_OPENSSL_OUTPUT_KEY_FILE}")

        if(_OPENSSL_RSA_PSS_PADDING)
            set(key_arg -newkey rsa-pss -pkeyopt rsa_keygen_bits:2048
                    -keyout ${key_output})
        else()
            set(key_arg -newkey rsa:2048 -keyout ${key_output})
        endif()
    endif()

    get_serial_number(BASE_NAME ${_OPENSSL_OUTPUT_CERT_FILE})

    # Create the certificate
    add_custom_command(
        VERBATIM
        COMMENT "Generating certificate: ${_OPENSSL_OUTPUT_CERT_FILE}"
        OUTPUT
            ${_OPENSSL_OUTPUT_CERT_FILE}
            ${key_output}
        WORKING_DIRECTORY "${_OPENSSL_WORKING_DIRECTORY}"
        # Pre-requesites: create folder and database
        COMMAND
            ${CMAKE_COMMAND} -E make_directory
                ${cert_dir} ${key_dir}
        # Create the certificate request
        COMMAND
            ${OPENSSL_COMMAND} req
                ${req_password}
                ${pkeyopt}
                -new ${key_arg}
                -config ${_OPENSSL_CONFIG_FILE}
                -out ${certRequestFile}
        # Certified with the CA
        COMMAND
            ${OPENSSL_COMMAND} x509
                -req -days ${_OPENSSL_DAYS}
                ${text_arg} ${digest_arg}
                -CA ${_OPENSSL_CA_CERT_FILE} -CAkey ${_OPENSSL_CA_KEY_FILE}
                -set_serial "0x${_${_OPENSSL_OUTPUT_CERT_FILE}_serial_number}"
                -extfile ${_OPENSSL_CA_CONFIG_FILE} ${ca_extension}
                ${ca_password_arg}
                -in ${certRequestFile}
                -out ${_OPENSSL_OUTPUT_CERT_FILE}
        # The certificate request is just a temporary file, so we remove it.
        COMMAND
            ${CMAKE_COMMAND} -E remove ${certRequestFile}
        DEPENDS
            ${key_dep}
            ${_OPENSSL_CONFIG_FILE}
            ${_OPENSSL_CA_CONFIG_FILE}
            ${_OPENSSL_CA_CERT_FILE}
            ${_OPENSSL_CA_KEY_FILE}
    )
endfunction()

function(connextdds_openssl_smime_sign)
    set(options)
    set(single_args INPUT OUTPUT SIGNER_CERTIFICATE PRIVATE_KEY_FILE)
    set(multi_args DEPENDS)
    cmake_parse_arguments(_OPENSSL
        "${options}"
        "${single_args}"
        "${multi_args}"
        ${ARGN})
    connextdds_check_required_arguments(
        _OPENSSL_INPUT _OPENSSL_OUTPUT
        _OPENSSL_SIGNER_CERTIFICATE _OPENSSL_PRIVATE_KEY_FILE
    )

    add_custom_command(
        VERBATIM
        COMMENT "Signing SMIME: ${_OPENSSL_INPUT}"
        OUTPUT "${_OPENSSL_OUTPUT}"
        COMMAND
            ${OPENSSL_COMMAND} smime -sign -text
                -in ${_OPENSSL_INPUT}
                -out ${_OPENSSL_OUTPUT}
                -signer ${_OPENSSL_SIGNER_CERTIFICATE}
                -inkey ${_OPENSSL_PRIVATE_KEY_FILE}
        DEPENDS
            ${_OPENSSL_DEPENDS}
            ${_OPENSSL_INPUT}
            ${_OPENSSL_SIGNER_CERTIFICATE}
            ${_OPENSSL_PRIVATE_KEY_FILE}
    )
endfunction()
