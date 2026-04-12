*** Settings ***
Library    AppiumLibrary
Resource   ../variables/device.robot

*** Keywords ***
Open Mobile App
    Open Application
    ...    ${REMOTE_URL}
    ...    platformName=${PLATFORM_NAME}
    ...    deviceName=${DEVICE_NAME}
    ...    automationName=${AUTOMATION_NAME}
    ...    appPackage=${APP_PACKAGE}
    ...    appActivity=${APP_ACTIVITY}

Close Mobile App
    Close Application