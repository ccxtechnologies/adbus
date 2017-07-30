#!/bin/bash

echo "==== Rebuilding Documentation ===="
rm ./source/modules.rst
rm ./source/adbus.*
sphinx-apidoc -o source/ ../adbus
make html
echo "==== Documentation Rebuilt ===="

