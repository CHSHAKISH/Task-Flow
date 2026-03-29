$content = Get-Content -Raw lib\main.dart
$content = $content -replace "with WidgetsBindingObserver ", ""
$content = $content -replace "(?sm)@override\s+void didChangeAppLifecycleState.*?\}\s*\}", ""
$content = $content -replace "(?sm)// Draft form controllers.*?DateTime\? _draftSelectedDate;", ""
$content = $content -replace "(?sm)_draftTitleController\?\.dispose\(\);\s*_draftDescriptionController\?\.dispose\(\);", ""
$content = $content -replace "(?sm)WidgetsBinding\.instance\.addObserver\(this\);", ""
$content = $content -replace "(?sm)WidgetsBinding\.instance\.removeObserver\(this\);", ""
Set-Content -Path lib\main.dart -Value $content
