#!/bin/bash
set -euo pipefail

# Get and export the current date in YYYYMMDD format
date=$(date +%Y%m%d)

dest_dir="runbooks-${date}"
# Remove the destination directory if it already exists
rm -rf "$dest_dir"

# Clone the repository
git clone --single-branch --branch master --no-checkout --filter=blob:none https://github.com/openshift/runbooks.git "$dest_dir"
cd "$dest_dir"
git sparse-checkout init --cone
git sparse-checkout set alerts
git checkout

# Remove non-markdown files and README.md files
find . -type f \( ! -name '*.md' -o -name 'README.md' -o -name example.md \) -exec rm -f {} +

# Remove empty directories and those named 'deprecated'
find . -depth -type d \( -empty -o -name 'deprecated' \) -exec rm -rf {} +

# Create the directory for merged alerts files
mkdir -p alerts-merged
cd alerts

# For each subdirectory, generate a merged markdown file
for dir in */; do
    if [ -d "$dir" ]; then
        dir_name="${dir%/}"
        merged_file="${dir_name}-merged.md"
        echo "Generating the merge file: ${merged_file}"
        > "$merged_file"
        
        # Merge all markdown files in the directory with headers and separators
        find "$dir" -type f -name '*.md' | sort | while read -r mdfile; do
            echo "Original Filename:  $(basename "$mdfile")" >> "$merged_file"
            echo "" >> "$merged_file"
            cat "$mdfile" >> "$merged_file"
            echo -e "\n\n" >> "$merged_file"
            echo "------------------------------" >> "$merged_file"
            echo -e "\n" >> "$merged_file"
        done
    fi
done

# Move merged markdown files to the alerts-merged directory
find . -maxdepth 1 -type f -name '*-merged.md' -exec mv -t ../alerts-merged/ {} +

# Copy remaining top-level markdown files to the alerts-merged directory
find . -maxdepth 1 -type f -name '*.md' -exec cp -t ../alerts-merged/ {} +
