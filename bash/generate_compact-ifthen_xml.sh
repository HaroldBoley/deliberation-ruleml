#!/bin/bash
# dc:rights [ 'Copyright 2015 RuleML Inc. -- Licensed under the RuleML Specification License, Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://ruleml.org/licensing/RSL1.0-RuleML. Disclaimer: THIS SPECIFICATION IS PROVIDED "AS IS" AND ANY EXPRESSED OR IMPLIED WARRANTIES, ..., EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. See the License for the specifics governing permissions and limitations under the License.' ]
# See ReadMe.text for instructions on running this script.
# 
#
shopt -s nullglob
BASH_HOME=$( cd "$(dirname "$0")" ; pwd -P )/ ;. "${BASH_HOME}path_config.sh";
mkdir -p "${INSTANCE_COMPACTIFTHEN_HOME}"
if [[ ${INSTANCE_COMPACTIFTHEN_HOME} ]]; then rm "${INSTANCE_COMPACTIFTHEN_HOME}"*.lrml  >> /dev/null 2>&1; fi

family="naffologeq_"
# Validate XSD schema
  schemanameNE="${family}ifthen-compact"
  schemaname="${schemanameNE}.xsd"
  sxfile="${XSD_HOME}${schemaname}"       
  "${BASH_HOME}aux_valxsd.sh" "${sxfile}"
  if [[ "$?" -ne "0" ]]; then
       echo "Schema Validation Failed for ${schemaname}"
       exit 1
   fi   

#   use oxygen to generate XML instances according to the configuration file for the compact-serialization driver
"$GENERATE_SCRIPT" "$COMPACTIFTHEN_CONFIG"

# Validate RNC schema
  schemaname="${schemanameNE}.rnc"
  sfile="${DRIVER_COMPACT_HOME}${schemaname}"       
  "${BASH_HOME}aux_valrnc.sh" "${sfile}"
  if [[ "$?" -ne "0" ]]; then
       echo "Schema Validation Failed for ${schemaname}"
       exit 1
   fi   

# Apply XSLT transforamtions - instance postprocessing
# transform in place for files in INSTANCE_COMPACTIFTHEN_HOME
#
# Check number of files to start with
files=( "${INSTANCE_COMPACTIFTHEN_HOME}"*.ruleml )
numfilesstart=${#files[@]}
echo "Number of Files to Start: ${numfilesstart}"

for f in "${INSTANCE_COMPACTIFTHEN_HOME}"*.ruleml
do
  filename=$(basename "$f")
  echo "Completing  ${filename}"
  "${BASH_HOME}aux_xslt.sh" "${f}" "${XSLT_HOME}instance-postprocessor/1.02_instance-postprocessor-compact-ifthen.xslt" "${f}"
  if [[ "$?" -ne "0" ]]; then
     echo "XSLT Transformation Failed for  ${filename}"
     exit 1
   fi
done

# Validate instances
for file in "${INSTANCE_COMPACTIFTHEN_HOME}"*.ruleml 
do
  filename=$(basename "${file}")
  echo "File ${filename}"
  "${BASH_HOME}aux_valrnc.sh" "${sfile}" "${file}"
  "${BASH_HOME}aux_valxsd.sh" "${sxfile}" "${file}"
  if [[ "$?" -ne "0" ]]; then
     echo "Completion Failed for  ${filename} - Removing"
     rm "${file}"
   fi
done

# Check if too many files were removed
files=( "${INSTANCE_COMPACTIFTHEN_HOME}"*.ruleml )
numfilesend=${#files[@]}
numfilesenddouble=2*$numfilesend
echo "Number of Files to End: ${numfilesend}"
  if [[ $numfilesenddouble -le $numfilesstart ]]; then
     echo "Completion Failed - Too Many Invalid Results"
     exit 1
   fi

# Apply XSLT transforamtions to canonicalize - strip whitespace only
# transform in place for files in INSTANCE_COMPACTIFTHEN_HOME
for f in "${INSTANCE_COMPACTIFTHEN_HOME}"*.ruleml
do
  filename=$(basename "$f")
  echo "Canonicalizing  ${filename}"
  "${BASH_HOME}aux_xslt.sh" "${f}" "${XSLT_HOME}instance-postprocessor/1.02_instance-postprocessor-stripwhitespace.xslt" "${f}"
  if [[ "$?" -ne "0" ]]; then
     echo "XSLT Transformation Failed for  ${filename}"
     exit 1
   fi
done

# Validate instances
for file in "${INSTANCE_COMPACTIFTHEN_HOME}"*.ruleml 
do
  filename=$(basename "${file}")
  echo "File ${filename}"
  "${BASH_HOME}aux_valrnc.sh" "${sfile}" "${file}"
  "${BASH_HOME}aux_valxsd.sh" "${sxfile}" "${file}"
  if [[ "$?" -ne "0" ]]; then
          echo "Validation Failed for ${file}"
          exit 1
  fi       
done

# Apply XSLT transforamtions for compactifying
# transform in place for files in INSTANCE_COMPACT_HOME
# Law: Cy = y
for f in "${INSTANCE_COMPACTIFTHEN_HOME}ca-"*.ruleml
do
  filename=$(basename "$f")
  echo "Re-Compactifying  ${filename}"
  fnew="${INSTANCE_COMPACTIFTHEN_HOME}re-${filename}"
  "${BASH_HOME}aux_xslt.sh" "${f}" "${XSLT_HOME}compactifier/1.02_compactifier-ifthen.xslt" "${fnew}"
  "${BASH_HOME}aux_xslt.sh" "${fnew}" "${XSLT_HOME}instance-postprocessor/1.02_instance-postprocessor-stripwhitespace.xslt" "${fnew}"
  read -r firstlineold<"${f}"
  read -r firstlinenew<"${fnew}"
  echo "Re-Compactified Comparing  ${filename}"
  if [[ "${firstlineold}" != "${firstlinenew}" ]]; then
     echo "Re-Compactification Failed for  ${filename}"
     diff -q "${f}" "${fnew}" 
     exit 1
   fi
done


# Apply XSLT transforamtions - normalize, then compactify (ifthen)
# transform into new file with "rt-" prefix for files in INSTANCE_COMPACTIFTHEN_HOME
# Law: CN = I
for f in "${INSTANCE_COMPACTIFTHEN_HOME}"*.ruleml
do
  filename=$(basename "$f")
  echo "Round-Trip Transforming  ${filename}"
  fnew="${INSTANCE_COMPACTIFTHEN_HOME}rt-${filename}"
  "${BASH_HOME}aux_xslt.sh" "${f}" "${XSLT_HOME}normalizer/1.02_normalizer.xslt" "${fnew}"
  "${BASH_HOME}aux_xslt.sh" "${fnew}" "${XSLT_HOME}compactifier/1.02_compactifier-ifthen.xslt" "${fnew}"
  "${BASH_HOME}aux_xslt.sh" "${fnew}" "${XSLT_HOME}instance-postprocessor/1.02_instance-postprocessor-stripwhitespace.xslt" "${fnew}"
  read -r firstlineold<"${f}"
  read -r firstlinenew<"${fnew}"
  echo "Round-Trip Comparing  ${filename}"
  if [[ "${firstlineold}" != "${firstlinenew}" ]]; then
     echo "XSLT Round Trip Failed for  ${filename}"
     diff -q "${f}" "${fnew}" 
     exit 1
   fi
done
