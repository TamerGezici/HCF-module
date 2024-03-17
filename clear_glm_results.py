import os
import argparse

# Create the arguments parser
parser = argparse.ArgumentParser(description='Find and optionally delete .nii files.')
parser.add_argument('--delete', action='store_true', help='Delete files after finding them.')

# Define function to get size of the directory
def get_dir_size(path='.'):
    total = 0
    with os.scandir(path) as it:
        for entry in it:
            if entry.is_file() and not os.path.islink(entry) and ('swrasub' in entry.name or 'wrasub' in entry.name) and entry.name.endswith('.nii'):
                total += entry.stat().st_size
            elif entry.is_dir():
                total += get_dir_size(entry.path)
    return total

def main():
    args = parser.parse_args()
    base_dir = 'GLM_results'
    matched_files = []

    # Get a list of all directories under the base_dir
    dirs = [d.path for d in os.scandir(base_dir) if d.is_dir()]

    # Iterate over the directories and their subdirectories
    for dir in dirs:
        for dirpath, dirnames, filenames in os.walk(dir):
            for filename in filenames:
                # Exclude .symlink files
                if filename.endswith('.symlink'):
                    continue

                filepath = os.path.join(dirpath, filename)

                # Check if the file is a symbolic link
                if os.path.islink(filepath):
                    continue

                # Check if the filename contains the desired string and ends with .nii
                if (filename.endswith('.nii') and ('swrasub' in filename or 'wrasub' in filename)):
                    matched_files.append(filepath)
                    
        # Calculate the total size of the dir in GB
        total_size = get_dir_size(dir) / (1024 * 1024 * 1024)
        print(f'Total size of {dir}: {total_size} GB')

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
