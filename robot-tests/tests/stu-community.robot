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
${COMMUNITY_NAME}       ชุมชนคนรักญี่ปุ่น
${COMMUNITY_DETAIL}     ชุมชนสำหรับคนที่รักญี่ปุ่นทั้งภาษาและวัฒนธรรมญี่ปุ่น
${COMMUNITY_TAG}        ญี่ปุ่น
${COMMUNITY_RULES}      ห้ามโพสต์เนื้อหาที่ไม่เกี่ยวข้องกับญี่ปุ่น
${FIND_COMMUNITY}       ศูนย์รวมคนรักวิทยาศาสตร์
${POST1}                มีใครมีสรุปเตรียมสอบชีวะไหมครับ
${COMMENT}              น่าสนใจครับ

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
    Click Element    xpath=//android.widget.Button[contains(@content-desc,"ชุมชน")]
#    Close Application

Create Community
    Sleep    3s
    Click Element    xpath=//android.widget.ImageView/android.view.View[1]
    Wait Until Page Contains    สร้างชุมชน    10s
    Click Element    xpath=//android.widget.ScrollView/android.widget.EditText[1]
    Input Text    xpath=//android.widget.ScrollView/android.widget.EditText[1]    ${COMMUNITY_NAME}
    Press Keycode    4
    Sleep    2s
    Click Element    xpath=//android.widget.ScrollView/android.widget.EditText[2]
    Input Text    xpath=//android.widget.ScrollView/android.widget.EditText[2]    ${COMMUNITY_DETAIL}
    Press Keycode    4
    Sleep    2s
    Click Element    accessibility_id=คลิกเพื่ออัปโหลดรูปภาพ
    Sleep    3s
    Click Element    xpath=//androidx.compose.ui.platform.ComposeView//android.view.View[5]//android.view.View[3]//android.view.View[2]/android.view.View
    Sleep    2s
    Click Element    accessibility_id=กลุ่มสาธารณะ
    Click Element    accessibility_id=เพิ่มแท็ก
    Sleep    2s
    Click Element    xpath=//android.widget.EditText
    Input Text    xpath=//android.widget.EditText    ${COMMUNITY_TAG}
    Sleep    3s
    Press Keycode    66
    Sleep    2s
    Click Element    accessibility_id=บันทึก
    Sleep    2s
    Click Element    xpath=//android.widget.ScrollView/android.widget.EditText[3]
    Input Text    xpath=//android.widget.ScrollView/android.widget.EditText[3]    ${COMMUNITY_RULES}
    Press Keycode    4
    Sleep    2s
    Click Element    accessibility_id=สร้าง

Post in Community
    Sleep    3s
    Wait Until Page Contains    ศูนย์รวมคนรักวิทยาศาสตร์    10s
    Click Element    xpath=//android.view.View/android.view.View/android.view.View[6]
    Wait Until Page Contains    สร้างโพสต์    10s
    Click Element    xpath=(//android.widget.EditText)
    Input Text    xpath=(//android.widget.EditText)    ${POST1}
    Click Element    accessibility_id=โพสต์
    Sleep    3s

Comment Post
    Sleep    3s
    Click Element    accessibility_id=โพสต์ใหม่สุด
    Sleep    2s    
    Click Element    accessibility_id=โพสต์เก่าสุด
    Sleep    2s
    Click Element    xpath=//android.view.View/android.view.View[8]
    Wait Until Page Contains    โพสต์    10s
    Click Element    xpath=(//android.widget.EditText)
    Input Text    xpath=(//android.widget.EditText)    ${COMMENT}
    Click Element    xpath=//android.view.View/android.view.View[3]
    Sleep    5s
    Click Element    xpath=//android.view.View[1]/android.widget.Button
    Sleep    3s

Find Community
    Sleep    5s
    Click Element    xpath=(//android.widget.EditText)
    Input Text    xpath=(//android.widget.EditText)    ${FIND_COMMUNITY}
    Press Keycode    4
    Sleep    3s
    Click Element    accessibility_id=ยังไม่เข้าร่วม
    Sleep    3s
