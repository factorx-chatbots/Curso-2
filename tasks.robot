*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Excel.Files
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.Tables
Library    RPA.Dialogs
Library    RPA.Robocorp.Vault

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Get Value Vault
    #Open Browser for orders
    Input the CSV file
    Fill the form using the data from the CSV file
    Create Archive Zip

*** Keywords ***
Get Value Vault
    ${secret}=    Get Secret    base_url
    Open Browser for orders    ${secret}

Open Browser for orders
    [Arguments]    ${secret}
    Open Available Browser    ${secret}[url]

Input the CSV file
    Add heading    Por favor ingresa la URL correcta para leer los pedidos (.csv)
    Add text input    url
    ${result}=    Run dialog
    Download the CSV file   ${result.url}
   
Download the CSV file
    [Arguments]    ${result.url}
    #Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    Download    ${result.url}    overwrite=True


Fill and submit the form for one order
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    address    ${row}[Address]
    Click Button    id:preview
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}/screens/robot_${row}[Order number].png
    Wait Until Keyword Succeeds    10x    1 sec    Click Order Button
    Wait Until Element Is Visible    id:receipt
    ${receipt_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_results_html}    ${OUTPUT_DIR}${/}/recibos/recibo_${row}[Order number].pdf 
    
    @{images} =    Create List    ${OUTPUT_DIR}${/}/screens/robot_${row}[Order number].png:align=center
    Add Files To Pdf    ${images}    ${OUTPUT_DIR}${/}/recibos/recibo_${row}[Order number].pdf    append=${True}
    Click Button  id:order-another  

Click Order Button
    FOR    ${i}    IN RANGE    9999999
        ${success} =    Is Element Visible    id:receipt
        Exit For Loop If    ${success}
        Click Button    id:order
    END
Close the annoying modal
    Wait Until Element Is Visible    css:div.alert-buttons
    Click Button    OK

Fill the form using the data from the CSV file
    ${orders}=    Read table from CSV    orders.csv    dialect=excel
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill and submit the form for one order    ${row}
        #Log    ${row}
    END

Create Archive Zip
    Archive Folder With Zip  ${OUTPUT_DIR}${/}recibos  mydocs.zip