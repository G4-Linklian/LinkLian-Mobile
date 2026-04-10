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
${SUGGESTION_IND}       ยอดเยี่ยมมากค่ะ
${SCORE_IND}            45
${SUGGESTION_GRO}       เลิศ
${SCORE_GRO}            5



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
    Click Element    xpath=//android.widget.Button[contains(@content-desc,"การบ้าน")]
#    Close Application

Select Class
    Sleep    3s
    Wait Until Page Contains    การบ้านของคุณ    10s
    Click Element    xpath=//android.view.View[contains(@content-desc,"คณิตศาสตร์พื้นฐาน")]
    Wait Until Page Contains    คณิตศาสตร์พื้นฐาน    10s

Check Individual Homework
    Sleep    3s
    Click Element    accessibility_id=กรองโพสต์
    Sleep    2s
    Click Element    accessibility_id=โพสต์ล่าสุด
    Scroll To Element    //android.view.View[contains(@content-desc,"แก้สมการ 10 ข้อ")]
    Click Element    xpath=//android.widget.ImageView[contains(@content-desc,"แก้สมการ 10 ข้อ")]
    Wait Until Page Contains    การบ้าน    10s
    Click Element   accessibility_id=ส่งงาน
    Click Element    //android.view.View[contains(@content-desc,"ส่งแล้ว")]
    Click Element     //android.view.View[contains(@content-desc,"ส่งเมื่อ") and contains(@content-desc,"ส่งแล้ว")]
    Sleep    3s
    Input Text    xpath=(//android.widget.EditText)[1]    ${SUGGESTION_IND}
    Input Text    xpath=(//android.widget.EditText)[2]    ${SCORE_IND}
    Click Element    accessibility_id=ให้คะแนน
    Click Element    xpath= //android.view.View[1]//android.widget.Button[1]

Check Group Homework
    Sleep    3s
    Scroll To Element    //android.view.View[contains(@content-desc,"แบบฝึกหัดสมการเชิงเส้นตัวแปรเดียว")]
    Click Element    xpath=//android.widget.ImageView[contains(@content-desc,"แบบฝึกหัดสมการเชิงเส้นตัวแปรเดียว")]
    Wait Until Page Contains    การบ้าน    10s
    Click Element    //android.view.View[contains(@content-desc,"ส่งแล้ว")]
    Scroll To Element    //android.view.View[contains(@content-desc,"กลุ่มเทสการลบ")]
    Click Element    xpath=//android.widget.ImageView[contains(@content-desc,"กลุ่มเทสการลบ")]
    Sleep    3s
    Input Text    xpath=(//android.widget.EditText)[1]    ${SUGGESTION_GRO}
    Input Text    xpath=(//android.widget.EditText)[2]    ${SCORE_GRO}
    Sleep    2s
    Click Element    accessibility_id=ให้คะแนน
    Click Element    xpath= //android.view.View[1]//android.widget.Button[1]
