*** Settings ***
Library    AppiumLibrary
Library    BuiltIn

*** Variables ***
${APPIUM_SERVER}        http://localhost:4723
${PLATFORM_NAME}        Android
${DEVICE_NAME}          emulator-5554
${APP}                  ${CURDIR}/../../build/app/outputs/flutter-apk/app-debug.apk
${EMAIL}                tanyatorn.kong@gmail.com
${PASSWORD}             LinkLian1511
${OTP}                  111111
${SUGGESTION_IND}       ยอดเยี่ยมมากค่ะ
${SCORE_IND}            45
${SUGGESTION_GRO}       เลิศ
${SCORE_GRO}            5

*** Test Cases ***
Login Teacher Successfully
    Open Application
    ...    ${APPIUM_SERVER}
    ...    platformName=${PLATFORM_NAME}
    ...    deviceName=${DEVICE_NAME}
    ...    automationName=UiAutomator2
    ...    app=${APP}

    Wait Until Element Is Visible    accessibility_id=อาจารย์/ครู    10s
    Click Element                    accessibility_id=อาจารย์/ครู
    Wait Until Element Is Visible    xpath=(//android.widget.EditText)[1]    10s
    Click Element                    xpath=(//android.widget.EditText)[1]
    Input Text                       xpath=(//android.widget.EditText)[1]    ${EMAIL}
    Press Keycode    4
    Sleep    3s
    Click Element                    xpath=(//android.widget.EditText)[2]
    Input Text                       xpath=(//android.widget.EditText)[2]    ${PASSWORD}
    Press Keycode    4
    Sleep    3s
    Click Element                    xpath=//android.widget.Button[@content-desc="เข้าสู่ระบบ"]
    Sleep    5s
    Wait Until Page Contains    รหัสยืนยัน    10s
    Click Element                    xpath=(//android.widget.EditText)
    Input Text                       xpath=(//android.widget.EditText)    ${OTP}
    Click Element                    accessibility_id=ยืนยัน
    Sleep    8s
    Click Element                    xpath=//android.widget.Button[contains(@content-desc,"การบ้าน")]
#    Close Application

Select Class
    Sleep    3s
    Wait Until Page Contains    การบ้านของคุณ    10s
    Click Element                    xpath=//android.view.View[contains(@content-desc,"คณิตศาสตร์พื้นฐาน")]
    Wait Until Page Contains    คณิตศาสตร์พื้นฐาน    10s

Check Individual Homework
    Sleep    3s
    Click Element                    accessibility_id=กรองโพสต์
    Sleep    2s
    Click Element                    accessibility_id=โพสต์ล่าสุด
    Sleep    3s
    Click Element                    android=new UiScrollable(new UiSelector().scrollable(true)).scrollIntoView(new UiSelector().descriptionContains("แก้สมการ 10 ข้อ"))
    Wait Until Page Contains    การบ้าน    10s
    Click Element                    accessibility_id=ส่งงาน
    Click Element                    xpath=//android.view.View[contains(@content-desc,"ส่งแล้ว")]
    Click Element                    xpath=//android.view.View[contains(@content-desc,"ส่งเมื่อ") and contains(@content-desc,"ส่งแล้ว")]
    Sleep    3s
    Click Element                    xpath=(//android.widget.EditText)[1]
    Input Text                       xpath=(//android.widget.EditText)[1]    ${SUGGESTION_IND}
    Press Keycode    4
    sleep    3s
    Click Element                    xpath=//android.view.View[3]//android.widget.EditText[2]
    Input Text                       xpath=//android.view.View[3]//android.widget.EditText[2]    ${SCORE_IND}
    Press Keycode    4
    Sleep    3s
    Click Element                    accessibility_id=ให้คะแนน
    Click Element                    xpath=//android.view.View[1]//android.widget.Button[1]

Check Group Homework
    Sleep    3s
    Click Element                    android=new UiScrollable(new UiSelector().scrollable(true)).scrollIntoView(new UiSelector().descriptionContains("แบบฝึกหัดสมการเชิงเส้นตัวแปรเดียว"))
    Wait Until Page Contains    การบ้าน    10s
    Click Element                    xpath=//android.view.View[contains(@content-desc,"ส่งแล้ว")]
    Sleep    3s
    Click Element                    android=new UiScrollable(new UiSelector().scrollable(true)).scrollIntoView(new UiSelector().descriptionContains("กลุ่มเทสการลบ"))
    Sleep    3s
    Click Element                    xpath=(//android.widget.EditText)[1]
    Input Text                       xpath=(//android.widget.EditText)[1]    ${SUGGESTION_GRO}
    Press Keycode    4
    sleep    2s
    Click Element                    xpath=//android.view.View[3]//android.widget.EditText[2]
    Input Text                       xpath=//android.view.View[3]//android.widget.EditText[2]    ${SCORE_GRO}
    Press Keycode    4
    Sleep    2s
    Click Element                    accessibility_id=ให้คะแนน
    Click Element                    xpath= //android.view.View[1]//android.widget.Button[1]
