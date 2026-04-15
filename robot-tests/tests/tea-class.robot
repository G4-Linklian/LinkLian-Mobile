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
${TOPPIC_ANNOUNCEMENT}  พรุ่งนี้ไม่มีการเรียนการสอนนะคะ อาจารย์มีประชุมวิชาการค่ะ
${DETAIL_ANNOUNCEMENT}  ทั้งสัปดาห์นี้ไม่มีการบ้านนะคะ นักเรียนสามารถทบทวนบทเรียนและเตรียมตัวสอบได้เลยค่ะ
${COMMENT}              อย่าลืมทบทวนบทเรียนเตรียมตัวสอบนะคะ
${HOMEWORK_NAME}        รายงานเรื่องนักคณิตศาสตร์ในดวงใจ
${HOMEWORK_DETAIL}      เขียนรายงานเกี่ยวกับนักคณิตศาสตร์ที่ชื่นชอบ ความยาวกระดาษ A4 1 หน้า พร้อมตกแต่ง

*** Test Cases ***
Login Teacher Successfully
    Open Application
    ...    ${APPIUM_SERVER}
    ...    platformName=${PLATFORM_NAME}
    ...    deviceName=${DEVICE_NAME}
    ...    automationName=UiAutomator2
    ...    app=${APP}

    Wait Until Element Is Visible    accessibility_id=อาจารย์/ครู    10s
    Click Element    accessibility_id=อาจารย์/ครู
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
    Click Element    xpath=//android.widget.Button[contains(@content-desc,"ห้องเรียน")]
#    Close Application

Select Class
    Sleep    5s
    Wait Until Page Contains    ห้องเรียนของคุณ    10s
    Click Element    xpath=//android.view.View[contains(@content-desc,"คณิตศาสตร์พื้นฐาน")]

Create Homework
    Wait Until Page Contains    คณิตศาสตร์พื้นฐาน    10s
    Sleep    3s
    Click Element    xpath=//android.widget.ImageView/android.view.View/android.view.View[3]
    Wait Until Page Contains    สร้างโพสต์    10s
    Click Element    accessibility_id=การบ้าน
    #Click Element    accessibility_id=งานเดี่ยว
    Sleep    3s
    Click Element    xpath=//android.view.View[7]//android.widget.EditText[1] 
    Input Text       xpath=//android.view.View[7]//android.widget.EditText[1]    ${HOMEWORK_NAME}
    Press Keycode    4
    Sleep    3s
    Click Element    xpath=//android.view.View[7]//android.widget.EditText[2]
    Input Text       xpath=//android.view.View[7]//android.widget.EditText[2]    ${HOMEWORK_DETAIL}
    Press Keycode    4
    Sleep    2s
    Click Element    xpath=//android.view.View[5]
    Sleep    3s
    Click Element    xpath=//android.widget.Button[contains(@content-desc,"24")]
    Click Element    accessibility_id=ตกลง
    Sleep    2s        
    Click Element    accessibility_id=สลับไปใช้โหมดป้อนข้อมูลข้อความ
    Sleep    2s    
    #Click Element    xpath=//android.widget.SeekBar[contains(@content-desc,"11")]
    #Click Element    xpath=//android.widget.SeekBar[contains(@content-desc,"59")]
    Click Element    accessibility_id=ตกลง
    Sleep    2s
    Click Element    xpath=//android.widget.EditText[@text="100.0"]
    Clear Text       xpath=//android.widget.EditText
    Input Text       xpath=//android.widget.EditText    10
    Click Element    accessibility_id=โพสต์
    Sleep    3s
    Click Element    xpath=//android.view.View[1]/android.widget.Button
    Sleep    2s
    Click Element    accessibility_id=ยกเลิกโพสต์

Create Announcement
    Wait Until Page Contains    คณิตศาสตร์พื้นฐาน    10s
    Sleep    3s
    Click Element    xpath=//android.widget.ImageView/android.view.View/android.view.View[3]
    Wait Until Page Contains    สร้างโพสต์    10s
    Click Element    accessibility_id=ประกาศ
    Click Element    xpath=//android.view.View[5]//android.widget.EditText[1] 
    Input Text       xpath=//android.view.View[5]//android.widget.EditText[1]    ${TOPPIC_ANNOUNCEMENT}
    Click Element    xpath=//android.view.View[5]//android.widget.EditText[2]
    Input Text      xpath=//android.view.View[5]//android.widget.EditText[2]    ${DETAIL_ANNOUNCEMENT}
    Click Element    accessibility_id=โพสต์
    Sleep    3s
    Click Element    xpath=//android.view.View[1]/android.widget.Button
    Sleep    2s
    Click Element    accessibility_id=ยกเลิกโพสต์

Comment Post
    Sleep    3s
    Click Element    accessibility_id=ทั้งหมด
    Sleep    2s    
    Click Element    accessibility_id=ประกาศ
    Sleep    2s
    Click Element    xpath=//android.view.View[contains(@content-desc,"ประกาศ") and contains(@content-desc,"ไม่มีการบ้าน")]
    Wait Until Page Contains    โพสต์    10s
    Click Element    xpath=(//android.widget.EditText)
    Input Text    xpath=(//android.widget.EditText)    ${COMMENT}
    Click Element    xpath=//android.view.View/android.view.View[3]
    Sleep    5s
    Click Element    xpath=//android.widget.FrameLayout[@resource-id="android:id/content"]//android.view.View[3]
    Sleep    3s