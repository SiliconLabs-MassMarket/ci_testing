*** Settings ***
Resource          ${RENODEKEYWORDS}
Library           RenodeKeywords
Library           Process
Library           OperatingSystem
Suite Setup       Setup
Suite Teardown    Teardown
Test Setup        Reset Emulation
Test Teardown     Test Teardown

*** Variables ***
${UART}           sysbus.uart0
${PROMPT}         Ready
${BINARY}         build/firmware.elf

*** Keywords ***
Setup
    [Documentation]    Initialize Renode
    Execute Command    verbosity log error

Teardown
    [Documentation]    Cleanup
    Execute Command    quit

Reset Emulation
    Execute Command    mach clear
    Execute Command    mach create
    Execute Command    machine LoadPlatformDescription @platforms/boards/stm32f4_discovery-kit.repl
    Execute Command    sysbus LoadELF @${BINARY}

Create Terminal Tester    [Arguments]    ${uart}=${UART}    ${timeout}=30
    Execute Command    emulation CreateUartPtyTerminal "term" "/tmp/uart" true
    Execute Command    connector Connect ${uart} term

*** Test Cases ***
Should Boot Successfully
    [Documentation]    Test that the firmware boots correctly
    Create Terminal Tester
    Start Emulation
    
    Wait For Line On Uart    ${PROMPT}    timeout=10
    Write Line To Uart    help
    Wait For Line On Uart    Available commands

Should Handle Commands
    [Documentation]    Test command processing
    Create Terminal Tester
    Start Emulation
    
    Wait For Line On Uart    ${PROMPT}
    Write Line To Uart    status
    Wait For Line On Uart    System Status    timeout=5

Should Respond to GPIO
    [Documentation]    Test GPIO functionality
    Execute Command    mach create
    Execute Command    machine LoadPlatformDescription @platforms/boards/stm32f4_discovery-kit.repl
    Execute Command    sysbus LoadELF @${BINARY}
    
    Start Emulation
    Execute Command    sysbus.gpioPortA.LED StateChanged true
    
    ${output}=    Execute Command    sysbus.gpioPortA.LED State
    Should Contain    ${output}    True
