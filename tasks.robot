*** Settings ***
*** Settings ***
Documentation     Robot 
...               robot realiza pedidos a diferentes lugares 
...               obtiene los archivos generados 
...               los guarda  cada recibido como un archivo pdf
...               guarda captura de pantalla de cada pedido
...               guarda la captura del robot que se genera
...               genera un archivo zip con todos los pdf y se almacena en el directorio de salida
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.PDF
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault
Library           RPA.Archive
Library           RPA.FileSystem

Task Setup        temp folder reset
Task Teardown     temp folder reset


*** Variables ***

*** Tasks ***
make robot order
    open website    https://robotsparebinindustries.com/#/robot-order
    ${orders}=    order get    https://robotsparebinindustries.com/orders.csv
    FOR    ${order}    IN    @{orders}
        close message web
        Fill the forms    ${order}
        Wait Until Keyword Succeeds    36s    1s    previe the robot
        Wait Until Keyword Succeeds    36s    1s    Submit the order
        ${pdf}=    Save the invoice as a PDF file    ${order}[Order number]
        ${screenshot}=    robot screenshot    ${order}[Order number]
        place capture in the PDF file of the invoice    ${screenshot}    ${pdf}
        order another robot
    END
    [Teardown]    Teardown


*** Keywords ***





temp folder reset
    ${dir_exists}=    Does Directory Exist    ${TEMP_DIR}
    IF    ${dir_exists}
        Remove Directory    ${TEMP_DIR}    recursive=True
    END
    Create Directory    ${TEMP_DIR}


open website
    [Arguments]    ${url}
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    No Operation


order get
    [Arguments]    ${url}
    Download    https://robotsparebinindustries.com/orders.csv    ${TEMP_DIR}${/}orders.csv    overwrite=True
    ${orders}=    Read table from CSV    ${TEMP_DIR}${/}orders.csv
    Log    Found columns: ${orders.columns}
    [Return]    ${orders}


close message web
    Click Button    Yep


fill the forms
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:head
    Select From List By Value    id:head    ${row}[Head]
    Click Element    xpath=//*[@id="id-body-${row}[Body]"]
    Input Text    xpath=//input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    css:#address    ${row}[Address]


previe the robot
    Click Element    id:preview
    Wait Until Element Is Visible    id:preview    3s


submit the order
    Click Element    id:order
    Wait Until Element Is Visible    id:order-completion    3s



Save the invoice as a PDF file
    [Arguments]    ${order_number}
    ${order_completion_html}=    Get Element Attribute    id:order-completion    innerHTML
    Html To Pdf    ${order_completion_html}    ${TEMP_DIR}${/}orders${/}order_${order_number}.pdf

Close the browser
    Add icon    Warning
    Add heading    QUIERES CERRAR EL NAVEGADOR?
    Add submit buttons    buttons=No,Yes    default=Yes
    ${result}=    Run dialog
    IF    $result.submit == "Yes"
        Close Browser
    END

robot screenshot
    [Arguments]    ${order_number}
    Screenshot    id:robot-preview-image    ${TEMP_DIR}${/}previews${/}robot_preview_${order_number}.png
    Open Pdf    ${TEMP_DIR}${/}orders${/}order_${order_number}.pdf
    ${files}=    Create List    ${TEMP_DIR}${/}previews${/}robot_preview_${order_number}.png
    Add Files To Pdf    ${files}    ${TEMP_DIR}${/}orders${/}order_${order_number}.pdf    append=True
    Close Pdf



place capture in the PDF file of the invoice
    [Arguments]    ${screenshot}    ${pdf}
    No Operation


order another robot
    Click Element    id:order-another


Create a ZIP file of the received
    No Operation
    Archive Folder With ZIP    ${TEMP_DIR}${/}orders    ${OUTPUT_DIR}${/}orders.zip    recursive=False    include=order*.pdf






Teardown
    Create a ZIP file of the received
    Close the browser
    temp folder reset
