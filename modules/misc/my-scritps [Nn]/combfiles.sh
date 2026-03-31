#!/usr/bin/env bash
set -euo pipefail

# If a path argument is given, cd into it first
if [[ $# -gt 0 ]]; then
  cd "$1"
fi

# Output file
output="all_files_combined.txt"

# Empty the output file
> "$output"

# Script's filename for self-exclusion
this_script="$(basename "$0")"

# Function to check if a file is a text file
is_text_file() {
  local file="$1"
  
  if [[ ! -s "$file" ]]; then
    return 0
  fi
  
  if file -b --mime "$file" | grep -q "^text/" || 
     file -b "$file" | grep -q "text" || 
     file -b "$file" | grep -q "ASCII" || 
     file -b "$file" | grep -q "UTF-8" || 
     file -b "$file" | grep -q "XML"; then
    return 0
  fi
  
  local ext="${file##*.}"
  ext="${ext,,}"
  
  case "$ext" in
    txt|md|java|xml|gradle|yml|yaml|json|js|html|css|c|cpp|h|hpp|py|sh|rb|pl|php|conf|ini|properties|gitignore|pro)
      return 0
      ;;
  esac
  
  if ! grep -q -m 1 -l $'\0' "$file" 2>/dev/null; then
    return 0
  fi
  
  return 1
}

is_lockfile() {
  local filename="$(basename "$1")"
  [[ "$filename" == "package-lock.json" || "$filename" == "yarn.lock" || 
     "$filename" == "flake.lock" || "$filename" == "Cargo.lock" ||
     "$filename" == "Gemfile.lock" || "$filename" == "poetry.lock" || 
     "$filename" =~ .*\.lock$ ]]
}

is_font_file() {
  local filename="$(basename "$1")"
  local ext="${filename##*.}"
  ext="${ext,,}"
  [[ "$ext" == "ttf" || "$ext" == "otf" || "$ext" == "woff" || "$ext" == "woff2" || "$ext" == "eot" ]]
}

is_image_file() {
  local filename="$(basename "$1")"
  local ext="${filename##*.}"
  ext="${ext,,}"
  [[ "$ext" == "png" || "$ext" == "jpg" || "$ext" == "jpeg" || "$ext" == "gif" || 
     "$ext" == "bmp" || "$ext" == "svg" || "$ext" == "ico" || "$ext" == "webp" ]]
}

is_binary_by_extension() {
  local filename="$(basename "$1")"
  local ext="${filename##*.}"
  ext="${ext,,}"
  
  case "$ext" in
    exe|dll|so|dylib|o|obj|bin|dat|db|sqlite|pyc|pyo|class|jar|war|ear|zip|tar|gz|tgz|bz2|7z|rar|pdf|doc|docx|xls|xlsx|ppt|pptx|odt|ods|odp|mp3|mp4|avi|mov|flv|wmv|wma|aac|m4a|wav|ogg|flac|bin|iso|img|apk|deb|rpm)
      return 0
      ;;
  esac
  
  return 1
}

# Check if we're in a git repository and gather files accordingly
if git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "Gathering files from git repository..."
  tracked_files=$(git ls-files)
  untracked_files=$(git ls-files --others --exclude-standard)
  all_files=$(printf "%s\n%s" "$tracked_files" "$untracked_files" | sort -u)
else
  echo "Not in a git repository, gathering all files from current directory..."
  all_files=$(find . -type f | sed 's|^\./||' | sort)
fi

# Count total files
total_files=$(echo "$all_files" | wc -l)
echo "Found $total_files files to process"

# Process each file
i=0
echo "$all_files" | while IFS= read -r file; do
  if [[ "$file" == "$output" || "$file" == "all_files_combined.txt" || 
        "$file" == "./all_files_combined.txt" || "$file" == "$this_script" || 
        "$file" == "file_list.sh" || "$file" == "./file_list.sh" || ! -f "$file" ]]; then
    continue
  fi

  i=$((i+1))
  if [ $((i % 50)) -eq 0 ]; then
    echo "Processing file $i of $total_files"
  fi

  echo "$file" >> "$output"
  echo "--------------------" >> "$output"

  if [[ $(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null) -gt 5000000 ]]; then
    echo "[large file content omitted]" >> "$output"
    echo -e "\n" >> "$output"
    continue
  fi

  if is_lockfile "$file"; then
    echo "[lock file content omitted]" >> "$output"
  elif is_font_file "$file"; then
    echo "[font file content omitted]" >> "$output"
  elif is_image_file "$file"; then
    echo "[image file content omitted]" >> "$output"
  elif is_binary_by_extension "$file"; then
    echo "[binary file content omitted]" >> "$output"
  elif ! is_text_file "$file"; then
    echo "[binary file content omitted]" >> "$output"
  else
    cat "$file" >> "$output"
  fi

  echo -e "\n" >> "$output"
done

echo "All files have been combined into $output"