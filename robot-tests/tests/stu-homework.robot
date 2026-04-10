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
    Click Element    xpath=//android.widget.Button[contains(@content-desc,"การบ้าน")]
#    Close Application

Select Class
    Sleep    3s
    Wait Until Page Contains    การบ้านของคุณ    10s
    Click Element    xpath=//android.view.View[contains(@content-desc,"คณิตศาสตร์พื้นฐาน")]
    Wait Until Page Contains    คณิตศาสตร์พื้นฐาน    10s

#Submit Individual Homework
    Sleep    3s
    Click Element    accessibility_id=กรองโพสต์
    Sleep    2s
    Click Element    accessibility_id=ยังไม่ส่ง
    Click Element    android=new UiScrollable(new UiSelector().scrollable(true)).scrollIntoView(new UiSelector().descriptionContains("ให้นักเรียนเขียนสมการเชิงเส้นสองตัวแปรมาคนละ"))
    Wait Until Page Contains    ส่งงาน    10s
    Click Element    accessibility_id=เพิ่มไฟล์
    Sleep    3s
    Click Element    accessibility_id=เพิ่มรูป
    Sleep    3s
    Click Element    xpath=//androidx.compose.ui.platform.ComposeView/android.view.View/android.view.View/android.view.View[5]/android.view.View[2]/android.view.View[2]/android.view.View
    Sleep    2s    
    Click Element    xpath=//androidx.compose.ui.platform.ComposeView/android.view.View/android.view.View/android.view.View[6]/android.view.View[3]/android.widget.Button
    Click Element    accessibility_id=ส่งงาน
    Sleep    3s
    Click Element    xpath=//android.view.View[1]/android.widget.Button

Submit Group Homework
    Sleep    3s
    Click Element    android=new UiScrollable(new UiSelector().scrollable(true)).scrollIntoView(new UiSelector().descriptionContains("การบ้านครั้งที่ 4"))
    Wait Until Page Contains    กลุ่ม    10s
    Click Element    xpath=//android.view.View[@content-desc="เลือกสมาชิก"]/android.widget.EditText[1]
    Input Text       xpath=//android.view.View[@content-desc="เลือกสมาชิก"]/android.widget.EditText[1]    ${GROUP_NAME}
    Sleep    2s
    Click Element    xpath=//android.view.View[@content-desc="เลือกสมาชิก"]/android.widget.EditText[2]
    Input Text    xpath=//android.view.View[@content-desc="เลือกสมาชิก"]/android.widget.EditText[2]    ${FIND_MEMBER}
    Sleep    2s
    Click Element    xpath=//android.view.View[@content-desc="กิตติกร พิมเทศ"]
        Click Element    android=new UiScrollable(new UiSelector().scrollable(true)).scrollIntoView(new UiSelector().descriptionContains("บันทึก"))
    Sleep    3s
    Click Element     xpath=//android.view.View[@content-desc="ส่งงาน"]
    Click Element    accessibility_id=เพิ่มไฟล์
    Sleep    3s
    Click Element    accessibility_id=เพิ่มรูป
    Sleep    3s
    Click Element    xpath=//androidx.compose.ui.platform.ComposeView/android.view.View/android.view.View/android.view.View[5]/android.view.View[2]/android.view.View[2]/android.view.View
    Sleep    3s
    Click Element    xpath=//androidx.compose.ui.platform.ComposeView/android.view.View/android.view.View/android.view.View[6]/android.view.View[3]/android.widget.Button
    Sleep    2s  
    Click Element    accessibility_id=ส่งงาน
