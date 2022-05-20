#!/bin/bash
set -euo pipefail

#nb: must be bash to support shopt globstar
shopt -s globstar

st=0

# Throw an error as an annotation.
# (message, file name, line number)
lint_error () {
	echo "::error file=$2,line=$3::$1"
	st=1
}

# Check grep and throw error if found.
# (message, grep pattern, file paths)
check_grep () {
	if gawk '$0 ~ pat {found = 1; print("::error file=" FILENAME ",line=" FNR "::" message)} END { exit !found }' message="$1" pat="$(echo "$2" | sed 's/\\/\\\\/g')" $3; then
		st=1
	fi
}

# Same as above, but match if grep matches, but NOT except pattern. See the comment grep as an example.
# (message, grep pattern, except pattern, file paths)
check_grep_with_exception () {
	if gawk '$0 ~ pat && $0 !~ except_pat {found = 1; print("::error file=" FILENAME ",line=" FNR "::" message)} END { exit !found }' message="$1" pat="$(echo $2 | sed 's/\\/\\\\/g')" except_pat="$(echo $3 | sed 's/\\/\\\\/g')" $4; then
		st=1
	fi
}

# Check grep against all maps.
# (message, grep pattern)
check_map_grep () {
	check_grep "$1" "$2" "_maps/**/*.dmm"
}

# Check grep with exception against all maps.
# (message, grep pattern, except pattern)
check_map_grep_with_exception () {
	check_grep_with_exception "$1" "$2" "$3" "_maps/**/*.dmm"
}

# Check grep against all code.
# (message, grep pattern)
check_code_grep () {
	check_grep "$1" "$2" "code/**/*.dm"
}

echo "::group::Checking for map issues"
check_map_grep "Non-TGM formatted map detected. Please convert it using Map Merger!" '^".+" = \(.+\)'
check_map_grep_with_exception "Unexpected commented out line detected in this map file. Please remove it." '//' '//MAP CONVERTED BY dmm2tgm.py THIS HEADER COMMENT PREVENTS RECONVERSION, DO NOT REMOVE'
check_map_grep "Merge conflict markers detected in map, please resolve all merge failures!" 'Merge conflict marker'
check_map_grep "Tag vars from icon state generation detected in maps, please remove them." '^\ttag = "icon'
check_map_grep "step_x/step_y variables detected in maps, please remove them." '^\tstep_[xy]'
check_map_grep "Incorrect pixel offset variables detected in maps, please remove them." '^\tpixel_[^xy]'
check_map_grep "Vareditted cables detected, please remove them." '/obj/structure/cable(/\w+)*\{'
check_map_grep "d1/d2 cable variables detected in maps, please remove them." '\td[1-2] ='
check_map_grep "Vareditted /area path use detected in maps, please replace with proper paths." '^/area/.+[\{]'
check_map_grep "Base /turf path use detected in maps, please replace with proper paths." '^/turf\s*[,\){]'
echo "::endgroup::"

echo "::group::Checking for whitespace issues"
check_code_grep "Space indentation detected." '(^ {2})|(^ [^ * ])|(^    +)'
check_code_grep "Mixed <tab><space> indentation detected." '^\t+ [^ *]'

# for f in code/**/*.dm; do
#     if [ "$(tail -c1 "$f")" != "" ]; then
# 		lint_error "File is missing a trailing newline." "$f" "1"
#     fi
# done
echo "::endgroup::"

echo "::group::Checking for common mistakes"
check_code_grep "Unmanaged global var use detected in code, please use the helpers." '^/*var/'
check_code_grep "Proc argument starting with 'var/'" '^/[[:alnum:]_/]\S+\(.*(var/|, ?var/.*).*\)'
check_code_grep "Balloon alert with improper arguments." 'balloon_alert\(".+"\)'
check_code_grep "Misspelling(s) of CENTCOM detected in code, please remove the extra M(s)." 'centcomm'
check_map_grep "Misspelling(s) of CENTCOM detected in map, please remove the extra M(s)." 'centcomm'
check_code_grep "Misspelling(s) of nanotrasen detected in code, please remove the extra N(s)." 'nanotransen'
check_map_grep "Misspelling(s) of nanotrasen detected in map, please remove the extra N(s)." 'nanotransen'
check_map_grep "Custom icon helper found. Please include dmis as standard assets instead for built-in maps." '/obj/effect/mapping_helpers/custom_icon'
echo "::endgroup::"

echo "::group::Checking for map JSON issues"
for json in _maps/*.json; do
	if echo "$json" | grep -P "[A-Z]"; then
		lint_error "Uppercase in a map json detected, these must be all lowercase." "$json" "1"
	fi

    map_path=$(jq -r '.map_path' $json)
    while read map_file; do
        filename="_maps/$map_path/$map_file"
        if [ ! -f "$filename" ]; then
            lint_error "found invalid file reference to $filename." "$json" "1"
        fi
    done < <(jq -r '[.map_file] | flatten | .[]' $json)
done
echo "::endgroup::"

exit $st
