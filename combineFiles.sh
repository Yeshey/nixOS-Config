#!/usr/bin/env bash
set -euo pipefail

# Output file
output="all_files_combined.txt"

# Empty the output file
> "$output"

# Script's filename for self-exclusion
this_script="$(basename "$0")"

# Function to check if a file is a text file
is_text_file() {
  local file="$1"
  
  # First check if it's empty (empty files are considered text)
  if [[ ! -s "$file" ]]; then
    return 0  # Empty file, consider as text
  fi
  
  # Use file command to check - simpler approach
  if file -b --mime "$file" | grep -q "^text/" || 
     file -b "$file" | grep -q "text" || 
     file -b "$file" | grep -q "ASCII" || 
     file -b "$file" | grep -q "UTF-8" || 
     file -b "$file" | grep -q "XML"; then
    return 0  # It's text
  fi
  
  # Special handling for known text file extensions
  local ext="${file##*.}"
  ext="${ext,,}"  # Convert to lowercase
  
  case "$ext" in
    txt|md|java|xml|gradle|yml|yaml|json|js|html|css|c|cpp|h|hpp|py|sh|rb|pl|php|conf|ini|properties|gitignore|pro)
      return 0  # Known text extensions
      ;;
  esac
  
  # Final check - try to grep for null bytes
  if ! grep -q -m 1 -l $'\0' "$file" 2>/dev/null; then
    # No null bytes found, likely text
    return 0
  fi
  
  return 1  # Assume binary
}

# Helper function for known lock files
is_lockfile() {
  local filename="$(basename "$1")"
  [[ "$filename" == "package-lock.json" || "$filename" == "yarn.lock" || 
     "$filename" == "flake.lock" || "$filename" == "Cargo.lock" ||
     "$filename" == "Gemfile.lock" || "$filename" == "poetry.lock" || 
     "$filename" =~ .*\.lock$ ]]
}

# Function to check if a file is a font file
is_font_file() {
  local filename="$(basename "$1")"
  local ext="${filename##*.}"
  ext="${ext,,}"  # Convert to lowercase
  
  [[ "$ext" == "ttf" || "$ext" == "otf" || "$ext" == "woff" || "$ext" == "woff2" || "$ext" == "eot" ]]
}

# Function to check if a file is an image
is_image_file() {
  local filename="$(basename "$1")"
  local ext="${filename##*.}"
  ext="${ext,,}"  # Convert to lowercase
  
  [[ "$ext" == "png" || "$ext" == "jpg" || "$ext" == "jpeg" || "$ext" == "gif" || 
     "$ext" == "bmp" || "$ext" == "svg" || "$ext" == "ico" || "$ext" == "webp" ]]
}

# Function to check if a file is binary based on extension first (for efficiency)
is_binary_by_extension() {
  local filename="$(basename "$1")"
  local ext="${filename##*.}"
  ext="${ext,,}"  # Convert to lowercase
  
  case "$ext" in
    # Binary extensions
    exe|dll|so|dylib|o|obj|bin|dat|db|sqlite|pyc|pyo|class|jar|war|ear|zip|tar|gz|tgz|bz2|7z|rar|pdf|doc|docx|xls|xlsx|ppt|pptx|odt|ods|odp|mp3|mp4|avi|mov|flv|wmv|wma|aac|m4a|wav|ogg|flac|bin|iso|img|apk|deb|rpm)
      return 0  # Binary extension
      ;;
  esac
  
  return 1  # Not a known binary extension
}

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "Error: Not in a git repository. This script must be run from within a git repo." >&2
  exit 1
fi

# Use git to find all tracked files AND untracked-but-not-ignored files
# This approach uses git's built-in functionality to honor .gitignore
echo "Gathering files from git repository..."

# Get list of files to process
# First, get all tracked files
tracked_files=$(git ls-files)

# Then, get all untracked files that aren't ignored by git (respects .gitignore)
untracked_files=$(git ls-files --others --exclude-standard)

# Combine the lists with newlines
all_files=$(printf "%s\n%s" "$tracked_files" "$untracked_files" | sort -u)

# Count total files
total_files=$(echo "$all_files" | wc -l)
echo "Found $total_files files to process"

# Process each file
i=0
echo "$all_files" | while IFS= read -r file; do
  # Skip our own output file, script file, or if file doesn't exist
  if [[ "$file" == "$output" || "$file" == "all_files_combined.txt" || 
        "$file" == "./all_files_combined.txt" || "$file" == "$this_script" || 
        "$file" == "file_list.sh" || "$file" == "./file_list.sh" || ! -f "$file" ]]; then
    continue
  fi

  # Update progress
  i=$((i+1))
  if [ $((i % 50)) -eq 0 ]; then
    echo "Processing file $i of $total_files"
  fi

  echo "$file" >> "$output"
  echo "--------------------" >> "$output"

  # Skip processing for very large files (>5MB)
  if [[ $(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null) -gt 5000000 ]]; then
    echo "[large file content omitted]" >> "$output"
    echo -e "\n" >> "$output"
    continue
  fi

  # Quick checks first - for efficiency
  if is_lockfile "$file"; then
    echo "[lock file content omitted]" >> "$output"
  elif is_font_file "$file"; then
    echo "[font file content omitted]" >> "$output"
  elif is_image_file "$file"; then
    echo "[image file content omitted]" >> "$output"
  elif is_binary_by_extension "$file"; then
    echo "[binary file content omitted]" >> "$output"
  # More expensive check last
  elif ! is_text_file "$file"; then
    echo "[binary file content omitted]" >> "$output"
  else
    # It's a text file, include its content
    cat "$file" >> "$output"
  fi

  # blank line after each file
  echo -e "\n" >> "$output"
done

echo "All files have been combined into $output"