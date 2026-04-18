*** Settings ***
Library    AppiumLibrary
Library    BuiltIn

*** Variables ***
${APPIUM_SERVER}        http://localhost:4723
${PLATFORM_NAME}        Android
${DEVICE_NAME}          emulator-5554
${APP}                  ${CURDIR}/../../build/app/outputs/flutter-apk/app-debug.apk
${EMAIL}                jantimaploy9@gmail.com
${PASSWORD}             LinkLian1511
${OTP}                  111111
${GROUP_NAME}           สู้อยู่สู้ต่อ
${FIND_MEMBER}          กิตติกร

*** Test Cases ***
Login Student Successfully
    Open Application
    ...    ${APPIUM_SERVER}
    ...    platformName=${PLATFORM_NAME}
    ...    deviceName=${DEVICE_NAME}
    ...    automationName=UiAutomator2
    ...    app=${APP}

    Wait Until Element Is Visible    accessibility_id=นักเรียน/นักศึกษา    10s
    Click Element    accessibility_id=นักเรียน/นักศึกษา
    Wait Until Element Is Visible    xpath=(//android.widget.EditText)[1]    10s
    Click Element    xpath=(//android.widget.EditText)[1]
    Input Text    xpath=(//android.widget.EditText)[1]    ${EMAIL}
    Press Keycode    4
    Sleep    3s
    Click Element    xpath=(//android.widget.EditText)[2]
    Input Text    xpath=(//android.widget.EditText)[2]    ${PASSWORD}
    Press Keycode    4
    Sleep    3s
    Click Element    xpath=//android.widget.Button[@content-desc="เข้าสู่ระบบ"]
    Sleep    5s
    Wait Until Page Contains    รหัสยืนยัน    10s
    Click Element    xpath=(//android.widget.EditText)
    Input Text    xpath=(//android.widget.EditText)    ${OTP}
    Click Element    accessibility_id=ยืนยัน    
    Sleep    5s
    Click Element    xpath=//android.widget.Button[contains(@content-desc,"โปรไฟล์")]
#    Close Application

Setting Student Profile
    Sleep    3s
    Wait Until Page Contains    โปรไฟล์    10s
    Sleep    3s
    Click Element    xpath=//android.widget.FrameLayout[@resource-id="android:id/content"]/android.widget.FrameLayout/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View[1]/android.widget.Button
    Click Element    accessibility_id=บัญชี
    
Edit Profile
    Sleep    3s
    Click Element    xpath=//android.widget.FrameLayout[@resource-id="android:id/content"]/android.widget.FrameLayout/android.view.View/android.view.View/android.view.View/android.view.View/android.view.View[1]/android.widget.Button[2]
    Click Element    xpath=//android.view.View[1]/android.widget.EditText
    Input Text    xpath=//android.view.View[1]/android.widget.EditText    จันทิมาพล ปล่อย
    Press Keycode    4
    Sleep    3s