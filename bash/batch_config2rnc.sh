#!/bin/bash
# dc:rights [ 'Copyright 2015 RuleML Inc. -- Licensed under the RuleML Specification License, Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://ruleml.org/licensing/RSL1.0-RuleML. Disclaimer: THIS SPECIFICATION IS PROVIDED "AS IS" AND ANY EXPRESSED OR IMPLIED WARRANTIES, ..., EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. See the License for the specifics governing permissions and limitations under the License.' ]
# Configures and validates local driver RNC schemas, generated locally by the MYNG engine, for testing purposes.
shopt -s nullglob
BASH_HOME=$( cd "$(dirname "$0")" ; pwd -P )/ ;. "${BASH_HOME}path_config.sh";

# creates the output directories if they don't exist, and clears them of RNC files, in case they already have contents
mkdir -p "${TEST_HOME}"
rm "${TEST_HOME}"*.rnc >> /dev/null 2>&1
rm "${RNC_HOME}/.htaccess" >> /dev/null 2>&1

echo  "IndexIgnore .htaccess */.??* *~ *# */HEADER* */README* all_ordered.rnc all_unordered.rnc local.prepend.php php-cli.ini phpinfo.php schema_rnc.php schema_rnc_test.php error_log">> "${RNC_HOME}/.htaccess"

while read line
do
    echo "Text read from file - $line"
    tokens=( $line )
    "${BASH_HOME}aux_myng2rnc.sh" "${tokens[1]}" "${TEST_HOME}${tokens[0]}_normal.rnc"
    "${BASH_HOME}aux_myng2rnc.sh" "${tokens[2]}" "${TEST_HOME}${tokens[0]}_relaxed.rnc"
    echo  "Redirect /1.02/relaxng/${tokens[0]}_normal.rnc http://deliberation.ruleml.org/1.02/myng-${tokens[1]}.rnc">> "${RNC_HOME}/.htaccess"
    echo  "Redirect /1.02/relaxng/${tokens[0]}_relaxed.rnc http://deliberation.ruleml.org/1.02/myng-${tokens[2]}.rnc">> "${RNC_HOME}/.htaccess"
done < "${BASH_HOME}config_rnc.txt"

echo "Redirect /1.02/relaxng/schema.rnc http://deliberation.ruleml.org/1.02/myng-b3f-d7-a7-l1-pfff-i7f-tf3f-q7-ef-s4f.rnc">> "${RNC_HOME}/.htaccess"

while read line
do
    echo "Text read from file - $line"
    tokens=( $line )
    "${BASH_HOME}aux_myng2rnc.sh" "${tokens[1]}" "${TEST_HOME}myng-${tokens[1]}.rnc"
    "${BASH_HOME}aux_myng2rnc.sh" "${tokens[2]}" "${TEST_HOME}myng-${tokens[2]}.rnc"
done < "${BASH_HOME}config_rnc_myng.txt"

for file in "${TEST_HOME}"*.rnc
do
  "${BASH_HOME}aux_valrnc.sh" "$file"
  if [ "$?" -ne "0" ]; then
     echo "Validation Failed for " "${file}"
     exit 1
   fi
done
