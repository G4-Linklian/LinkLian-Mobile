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
${CREATE_QUESTIONS}     ขออนุญาติสอบถามค่ะพรุ่งนี้ใส่ชุดนักเรียนใช่มั้ยคะ
${COMMENT}              ทำเกินได้ไหมคะ
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
    Sleep    8s

#    Close Application

Select Class
    Sleep    3s
    Wait Until Page Contains    ห้องเรียนของคุณ    10s
    Click Element    xpath=//android.view.View[contains(@content-desc,"คณิตศาสตร์พื้นฐาน")]

Create Post
    Wait Until Page Contains    คณิตศาสตร์พื้นฐาน    10s
    Sleep    3s
    Click Element    xpath=//android.widget.ImageView/android.view.View/android.view.View[3]
    Wait Until Page Contains    สร้างโพสต์    10s
    Click Element    xpath=(//android.widget.EditText)
    Input Text    xpath=(//android.widget.EditText)    ${CREATE_QUESTIONS}
    Click Element    accessibility_id=โพสต์
    Sleep    3s
    Click Element    xpath=//android.view.View[1]/android.widget.Button
    Sleep    2s
    Click Element    accessibility_id=ยกเลิกโพสต์

Comment Post
    Sleep    3s
    Click Element    accessibility_id=ทั้งหมด
    Sleep    2s    
    Click Element    accessibility_id=การบ้าน
    Sleep    2s
    Click Element    xpath=//android.view.View[2]/android.view.View
    Wait Until Page Contains    โพสต์    10s
    Click Element    xpath=(//android.widget.EditText)
    Input Text    xpath=(//android.widget.EditText)    ${COMMENT}
    Click Element    xpath=//android.view.View/android.view.View[3]
    Sleep    5s
    Click Element    xpath=//android.view.View[1]/android.widget.Button
    Sleep    3s