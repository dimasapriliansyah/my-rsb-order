*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.Tables
Library    RPA.Excel.Files
Library    RPA.HTTP
Library    RPA.PDF
Library    RPA.Archive
Library    OperatingSystem
Library    RPA.Dialogs
Library    RPA.Robocorp.Vault

*** Variables ***
${CSV_FILE_PATH}=           ${CURDIR}/orders.csv
${TEMP}=    ${CURDIR}${/}temp
${PDF_TEMP}=    ${CURDIR}${/}temp/pdf
${SCREENSHOT_TEMP}=    ${CURDIR}${/}temp/ss
${GLOBAL_RETRY_AMOUNT}=     10x
${GLOBAL_RETRY_INTERVAL}=   0.5s



*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${url_csv_file}=    Ask user the csv url 
    ${orders}=    Get orders    ${url_csv_file}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close Browser and Cleanup temp directory


*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    application
    Open Available Browser    ${secret}[orderURL]
Ask user the csv url
    Add text input    csv_url    label=CSV URL
    ${response}=    Run dialog
    [Return]    ${response.csv_url}
Get orders
    [Arguments]    ${url_csv_file}
    Download    ${url_csv_file}  overwrite=True
    ${orders}=    Read table from CSV    ${CSV_FILE_PATH}    header=TRUE
    [Return]    ${orders}
Close the annoying modal
    Click Button    OK
Fill the form
    [Arguments]    ${order}
    
    Select From List By Value   head    ${order}[Head]
    
    Select Radio Button    body    ${order}[Body]

    Input Text    css:#root > div > div.container > div > div.col-sm-7 > form > div:nth-child(3) > input
    ...           ${order}[Legs]

    Input Text    address    ${order}[Address]

Preview the robot
    Click Button    Preview
Submit the order
    Wait Until Keyword Succeeds    
    ...    ${GLOBAL_RETRY_AMOUNT}    
    ...    ${GLOBAL_RETRY_INTERVAL} 
    ...    Ordering Success  
Ordering Success   
    Click Button    order  
    Wait Until Element Is Visible    id:order-completion                     
Store the receipt as a PDF file
    [Arguments]    ${order_number}
    # Wait Until Element Is Visible    id:order-completion    20s
    ${order_receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_receipt_html}    ${PDF_TEMP}${/}order_receipt_${order_number}.pdf
    [Return]    ${PDF_TEMP}${/}order_receipt_${order_number}.pdf
Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${screenshot}    Screenshot    css:div#robot-preview    ${SCREENSHOT_TEMP}${/}order-${order_number}.png
    [Return]    ${SCREENSHOT_TEMP}${/}order-${order_number}.png
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf} 
    ${file}=    Create List
    ...         ${screenshot}        
    Add Files To Pdf     ${file}    ${pdf}    append
Go to order another robot
    Click Button    order-another
Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/Receipts.zip
    Archive Folder With Zip
        ...    ${PDF_TEMP}
        ...    ${zip_file_name}
Close Browser and Cleanup temp directory
    Close Browser
    Remove Directory    ${TEMP}    True