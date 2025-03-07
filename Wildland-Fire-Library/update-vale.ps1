$valeConfig = @"
StylesPath = styles
MinAlertLevel = suggestion

[*{md,txt}]
BasedOnStyles = Vale
"@

# Update the .vale.ini file
$valeConfig | Out-File -FilePath ".vale.ini" -Encoding UTF8 -NoNewline

Write-Host ".vale.ini file has been updated!"
