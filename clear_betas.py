import os
import argparse

# Create the arguments parser
parser = argparse.ArgumentParser(description='Find and optionally delete .nii files.')
parser.add_argument('--delete', action='store_true', help='Delete files after finding them.')

def get_files_size(file_list):
    total_size = 0
    for file in file_list:
        total_size += os.path.getsize(file)
    return total_size / (1024 * 1024 * 1024)

def main():
    args = parser.parse_args()
    base_dir = 'GLM_results'
    target_folder = 'aamod_firstlevel_contrasts_00001'
    matched_files = []

    # Iterate over the directories and their subdirectories
    for dirpath, dirnames, filenames in os.walk(base_dir):
        if os.path.basename(dirpath) == target_folder:
            for filename in filenames:
                # Exclude .symlink files
                if filename.endswith('.symlink'):
                    continue

                filepath = os.path.join(dirpath, filename)

                # Check if the file is a symbolic link
                if os.path.islink(filepath):
                    continue

                # Check if the filename contains the string "beta" and ends with .nii
                if (filename.endswith('.nii') and ('beta' in filename)):
                    matched_files.append(filepath)

    # Print the matched files
    for file in matched_files:
        print(f"Matched file: {file}")
            
    # Calculate the total size of matched_files in GB
    total_size = get_files_size(matched_files)
    print(f'Total size of matched files: {total_size} GB')

    # Check if the delete option is set and confirm before deleting
    if args.delete:
        if matched_files:
            print("\nThe following files will be deleted:")
            for filepath in matched_files:
                print(filepath)
            confirmation = input("\nAre you sure you want to delete these files? (yes/no): ")
            if confirmation.lower() == 'yes':
                for filepath in matched_files:
                    os.remove(filepath)
                    print(f"Deleted: {filepath}")
            else:
                print("Operation cancelled.")
        else:
            print("No matching files to delete.")

if __name__ == "__main__":
    main()
