
DIRECTORY="."

# Loop through each file or folder in the directory
for filename in "$DIRECTORY"/*; do
  # Check if the current name contains the old date "20241010"
  if [[ "$filename" =~ 2024[0-9]{4} ]]; then
    # Replace the matched date with the desired date 20241008
    new_filename=$(echo "$filename" | sed -E 's/2024[0-9]{4}/20241008/')

    # Rename the folder or file
    mv "$filename" "$new_filename"

    # Print the result
    echo "Renamed: $filename to $new_filename"
  fi
done


