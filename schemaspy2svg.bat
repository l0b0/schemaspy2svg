@echo off

if "%~s1"=="" goto END

rem Convert dot files to SVG
dot -O -Tsvg %~s1\diagrams\*.dot
dot -O -Tsvg %~s1\diagrams\summary\*.dot

rem Fix the URLs in SVG files
for %%i in (%~s1\diagrams\summary\*.svg) do (
    perl -p -i.bak -e "s#^^^&lt;a xlink:href=\&quot;#^&lt;a target=\&quot;_top\&quot; xlink:href=\&quot;../../#g&quot; %%i
)
for %%i in (%~s1\diagrams\*.svg) do (
    perl -p -i.bak -e &quot;s#^^^&lt;a xlink:href=\&quot;#^&lt;a target=\&quot;_top\&quot; xlink:href=\&quot;../tables/#g&quot; %%i
)

rem Refer to SVG instead of PNG images in HTML files
for %%i in (%~s1\*.html) do (
    perl -p -i.bak -e &quot;s#<img>#$7#g" %%i
)
for %%i in ("%~s1\tables\*.html") do (
    perl -p -i.bak -e "s#<img>#$7#g" %%i
)

rem Clean up backup files and no longer needed PNG / DOT files
del "%~s1\*.bak" "%~s1\tables\*.bak" "%~s1\diagrams\*.bak" "%~s1\diagrams\*.png" "%~s1\diagrams\summary\*.bak" "%~s1\diagrams\summary\*.png"

:END
