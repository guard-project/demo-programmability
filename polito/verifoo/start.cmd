@echo off
(
    cd "%~dp0"
    java -jar "%~dp0\verifoo-0.0.1-snapshot.jar" -cp "%~dp0"
)