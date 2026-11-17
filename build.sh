#!/bin/sh
# Biên dịch không cần NetBeans (JDK 8+)
cd "$(dirname "$0")" || exit 1
rm -rf out && mkdir -p out dist
find src -name '*.java' > sources.txt
javac -encoding UTF-8 -source 8 -target 8 -d out @sources.txt || { rm -f sources.txt; exit 1; }
rm -f sources.txt
cp -r src/assets out/assets
jar cfm dist/CroakSquad.jar manifest.mf -C out .
echo "Xong: dist/CroakSquad.jar"
