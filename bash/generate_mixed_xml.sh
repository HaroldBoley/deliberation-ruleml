#!/bin/bash
# dc:rights [ 'Copyright 2015 RuleML Inc. -- Licensed under the RuleML Specification License, Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://ruleml.org/licensing/RSL1.0-RuleML. Disclaimer: THIS SPECIFICATION IS PROVIDED "AS IS" AND ANY EXPRESSED OR IMPLIED WARRANTIES, ..., EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. See the License for the specifics governing permissions and limitations under the License.' ]
# See ReadMe.text for instructions on running this script.

shopt -s nullglob
BASH_HOME=$( cd "$(dirname "$0")" ; pwd -P )/ ;. "${BASH_HOME}path_config.sh";
mkdir -p "${INSTANCE_NORMAL_HOME}"
rm "${INSTANCE_NORMAL_HOME}"*.ruleml  >> /dev/null 2>&1
mkdir -p "${INSTANCE_COMPACT_HOME}"
rm "${INSTANCE_COMPACT_HOME}"*.ruleml  >> /dev/null 2>&1
mkdir -p "${INSTANCE_MIXED_HOME}"
rm "${INSTANCE_MIXED_HOME}"*.ruleml  >> /dev/null 2>&1

family="naffologeq"
mschemanameNE="${family}"
nschemanameNE="${family}_normal"
cschemanameNE="${family}_compact"
mschemaname="${mschemanameNE}.xsd"
nschemaname="${nschemanameNE}.xsd"
cschemaname="${cschemanameNE}.xsd"
mxsfile="${XSD_HOME}${mschemaname}"       
nxsfile="${XSD_NORMAL}${nschemaname}"       
cxsfile="${XSD_NORMAL}${cschemaname}"       

# Validate XSD schema
  echo "Start XSD Schema Validation"
  "${BASH_HOME}aux_valxsd.sh" "${mxsfile}"
  if [[ "$?" -ne "0" ]]; then
       echo "Schema Validation Failed for ${schemaname}"
       exit 1
   fi   

#   use oxygen to generate XML instances according to the configuration file for the normal-serialization driver"
echo "Start Instance Generation"
"$GENERATE_SCRIPT" "$MIXED_CONFIG"

# Validate RNC schema
  echo "Start RNC Schema Validation"
  rschemaname="${family}_relaxed.rnc"
  rsfile="${DRIVER_HOME}${rschemaname}"       
  "${BASH_HOME}aux_valrnc.sh" "${rsfile}"
  if [[ "$?" -ne "0" ]]; then
       echo "Schema Validation Failed for ${mschemaname}"
       exit 1
   fi   

# Apply XSLT transforamtions - instance postprocessing
# transform in place for files in INSTANCE_NORMAL_HOME
#
# Check number of files to start with
files=( "${INSTANCE_MIXED_HOME}"*.ruleml )
numfilesstart=${#files[@]}
echo "Number of Files to Start: ${numfilesstart}"

for f in "${INSTANCE_MIXED_HOME}"*.ruleml
do
  filename=$(basename "$f")
  echo "Completing  ${filename}"
  "${BASH_HOME}aux_xslt.sh" "${f}" "${XSLT_HOME}instance-postprocessor/instance-postprocessor.xslt" "${f}"
  if [[ "$?" -ne "0" ]]; then
     echo "XSLT Transformation Failed for  ${filename}"
     exit 1
   fi
done

# Validate instances
# Test: output of the instance postprocessor applied to the generated instances from the mixed serialization schema
#       validate against the relaxed serialization RNC schema and the mixed serialization XSD schema
for file in "${INSTANCE_MIXED_HOME}"*.ruleml 
do
  sleep 2
  filename=$(basename "${file}")
  echo "File ${filename}"
  "${BASH_HOME}aux_valrnc.sh" "${rsfile}" "${file}"
  if [[ "$?" -ne "0" ]]; then
     echo "Completion Failed for  ${filename} - Removing"
     rm "${file}"
   fi
  "${BASH_HOME}aux_valxsd.sh" "${mxsfile}" "${file}"
  if [[ "$?" -ne "0" ]]; then
     echo "Completion Failed for  ${filename} - Removing"
     rm "${file}"
   fi
done

# Check if too many files were removed
files=( "${INSTANCE_MIXED_HOME}"*.ruleml )
numfilesend=${#files[@]}
numfilesenddouble=2*$numfilesend
echo "Number of Files to End: ${numfilesend}"
  if [[ $numfilesenddouble -le $numfilesstart ]]; then
     echo "Completion Failed - Too Many Invalid Results"
     exit 1
   fi

# Validate compact schema
  echo "Start RNC Compact Schema Validation"
  cschemaname="${cschemanameNE}.rnc"
  csfile="${DRIVER_COMPACT_HOME}${cschemaname}"       
  "${BASH_HOME}aux_valrnc.sh" "${csfile}"
  if [[ "$?" -ne "0" ]]; then
       echo "Schema Validation Failed for ${cschemaname}"
       exit 1
   fi   

# Apply XSLT transforamtions for compactifying
# transform files in INSTANCE_MIXED_HOME into INSTANCE_COMPACT_HOME 
for f in "${INSTANCE_MIXED_HOME}"*.ruleml
do
  filename=$(basename "$f")
  echo "Compactifying  ${filename}"
  fnew="${INSTANCE_COMPACT_HOME}${filename}"
  "${BASH_HOME}aux_xslt.sh" "${f}" "${XSLT_HOME}compactifier/compactifier.xslt" "${fnew}"
  if [[ "$?" -ne "0" ]]; then
     echo "XSLT Transformation Failed for  ${filename}"
     exit 1
   fi
done

# Validate instances
# Test: output of the compactifier validates against the compact serialization RNC and XSD schema
for file in "${INSTANCE_COMPACT_HOME}"*.ruleml 
do
  sleep 2
  filename=$(basename "${file}")
  echo "Validating File ${filename}"
  "${BASH_HOME}aux_valrnc.sh" "${csfile}" "${file}"
  "${BASH_HOME}aux_valxsd.sh" "${cxsfile}" "${file}"
  if [[ "$?" -ne "0" ]]; then
          echo "Validation Failed for ${file}"
          exit 1
  fi       
done

# Validate normal schema
  echo "Start RNC Normal Schema Validation"
  nschemaname="${nschemanameNE}.rnc"
  nsfile="${DRIVER_NORMAL_HOME}${nschemaname}"       
  "${BASH_HOME}aux_valrnc.sh" "${nsfile}"
  if [[ "$?" -ne "0" ]]; then
       echo "Schema Validation Failed for ${nschemaname}"
       exit 1
   fi   

# Apply XSLT transforamtions for normalizing
# transform files in INSTANCE_MIXED_HOME into INSTANCE_NORMAL_HOME 
for f in "${INSTANCE_MIXED_HOME}"*.ruleml
do
  filename=$(basename "$f")
  echo "Normalizing  ${filename}"
  fnew="${INSTANCE_NORMAL_HOME}${filename}"
  "${BASH_HOME}aux_xslt.sh" "${f}" "${XSLT_HOME}normalizer/normalizer.xslt" "${fnew}"
  if [[ "$?" -ne "0" ]]; then
     echo "XSLT Transformation Failed for  ${filename}"
     exit 1
   fi
done

# Validate instances
# Test: output of the normalizer validates against the normalized RNC and XSDserialization schema
for file in "${INSTANCE_NORMAL_HOME}"*.ruleml 
do
  sleep 2
  filename=$(basename "${file}")
  echo "Validating File ${filename}"
  "${BASH_HOME}aux_valrnc.sh" "${nsfile}" "${file}"
  "${BASH_HOME}aux_valxsd.sh" "${nxsfile}" "${file}"
  if [[ "$?" -ne "0" ]]; then
          echo "Validation Failed for ${file}"
          exit 1
  fi       
done

# Apply XSLT transforamtions for canonicalizing instances of the mixed schema into the normalized serialization (P = compactify, normalize, and strip whitespace)
# transform into INSTANCE_NORMAL_HOME
for f in "${INSTANCE_MIXED_HOME}"*.ruleml
do
  filename=$(basename "$f")
  echo "Canonicalizing  ${filename}"
  fnew="${INSTANCE_NORMAL_HOME}${filename}"
  "${BASH_HOME}aux_xslt.sh" "${f}" "${XSLT_HOME}compactifier/compactifier.xslt" "${fnew}"
  "${BASH_HOME}aux_xslt.sh" "${fnew}" "${XSLT_HOME}normalizer/normalizer.xslt" "${fnew}"
  "${BASH_HOME}aux_xslt.sh" "${fnew}" "${XSLT_HOME}instance-postprocessor/instance-postprocessor-stripwhitespace.xslt" "${fnew}"
  if [[ "$?" -ne "0" ]]; then
     echo "XSLT Transformation Failed for  ${filename}"
     exit 1
   fi
done

# Validate instances
for file in "${INSTANCE_NORMAL_HOME}"*.ruleml 
do
  sleep 2
  filename=$(basename "${file}")
  echo "Validating File ${filename}"
  "${BASH_HOME}aux_valrnc.sh" "${nsfile}" "${file}"
  "${BASH_HOME}aux_valxsd.sh" "${nxsfile}" "${file}"
  if [[ "$?" -ne "0" ]]; then
          echo "Validation Failed for ${file}"
          exit 1
  fi       
done

# Apply XSLT transforamtions for normalizing
# transform in place for files in INSTANCE_NORMAL_HOME
# Law: If y = Px, then Ny = y
for f in "${INSTANCE_NORMAL_HOME}"*.ruleml
do
  filename=$(basename "$f")
  echo "Re-Normalizing  ${filename}"
  fnew="${INSTANCE_NORMAL_HOME}re-${filename}"
  "${BASH_HOME}aux_xslt.sh" "${f}" "${XSLT_HOME}normalizer/normalizer.xslt" "${fnew}"
  "${BASH_HOME}aux_xslt.sh" "${fnew}" "${XSLT_HOME}instance-postprocessor/instance-postprocessor-stripwhitespace.xslt" "${fnew}"
  read -r firstlineold<"${f}"
  read -r firstlinenew<"${fnew}"
  echo "Re-Normalized Comparing  ${filename}"
  if [[ "${firstlineold}" != "${firstlinenew}" ]]; then
     echo "Re-Normalization Failed for  ${filename}"
     diff -q "${f}" "${fnew}" 
     exit 1
   fi
done

# Apply XSLT transforamtions for canonicalizing instances of the mixed schema into the compact serialization (Q = compactify, and strip whitespace)
# transform in place for files in INSTANCE_COMPACT_HOME
for f in "${INSTANCE_MIXED_HOME}"*.ruleml
do
  filename=$(basename "$f")
  echo "Canonicalizing  ${filename}"
  fnew="${INSTANCE_COMPACT_HOME}${filename}"
  "${BASH_HOME}aux_xslt.sh" "${f}" "${XSLT_HOME}compactifier/compactifier.xslt" "${fnew}"
  "${BASH_HOME}aux_xslt.sh" "${fnew}" "${XSLT_HOME}instance-postprocessor/instance-postprocessor-stripwhitespace.xslt" "${fnew}"
  if [[ "$?" -ne "0" ]]; then
     echo "XSLT Transformation Failed for  ${filename}"
     exit 1
   fi
done

# Apply XSLT transforamtions for compactifying
# transform in place for files in INSTANCE_COMPACT_HOME
# Law: If y = Qx, then Cy = y
for f in "${INSTANCE_COMPACT_HOME}"*.ruleml
do
  filename=$(basename "$f")
  echo "Re-Compactifying  ${filename}"
  fnew="${INSTANCE_COMPACT_HOME}re-${filename}"
  "${BASH_HOME}aux_xslt.sh" "${f}" "${XSLT_HOME}compactifier/compactifier.xslt" "${fnew}"
  "${BASH_HOME}aux_xslt.sh" "${fnew}" "${XSLT_HOME}instance-postprocessor/instance-postprocessor-stripwhitespace.xslt" "${fnew}"
  read -r firstlineold<"${f}"
  read -r firstlinenew<"${fnew}"
  echo "Re-Compactified Comparing  ${filename}"
  if [[ "${firstlineold}" != "${firstlinenew}" ]]; then
     echo "Re-Compactification Failed for  ${filename}"
     diff -q "${f}" "${fnew}" 
     exit 1
   fi
done
