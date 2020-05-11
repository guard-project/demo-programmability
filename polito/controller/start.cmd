@echo off
(
    timeout 10
    java -jar "%~dp0\controller-0.0.1-snapshot.jar"
)