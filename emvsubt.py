#!/usr/bin/python3
import os
import re
import argparse
import re
import glob

parser = argparse.ArgumentParser()
parser.add_argument("-dir", "--input_directory", type=str, help="Input Directory")
parser.add_argument("-output-dir", "--output_directory", type=str, help="Output directory uses input directory if not set")
parser.add_argument("-f", "--files", type=str, help="input files")

args = parser.parse_args()

input_directory = args.input_directory
output_directory = args.output_directory
input_files = args.files

if input_files is None:
    parser.error("-f | --files is required");

if input_directory is not None and not input_directory.endswith('/'):
    input_directory = input_directory + "/"


if output_directory is not None and not output_directory.endswith("/"):
    output_directory = output_directory + "/"

def find_recursive_files(input_directory):
    '''find files recursive'''
    input_directory = input_directory if input_directory is not None else '.'
    file_list = []
    for root, _, files in os.walk(input_directory):
        for file in files:
            file_path = os.path.join(root, file)
            file_list.append(file_path.replace("./", ""))
    return file_list

def find_file(files_input: str, input_directory: str):
    '''find files with globs'''
    files_input_array = files_input.split(',');
    fs: list[str] = []
    for fi in files_input_array:
        fs = fs + [f if input_directory is None else input_directory+f for f in glob.glob(fi, recursive=True, root_dir=input_directory)]
    fs =  list(set(fs))
    return fs
    

files = []
# Find all YAML files in the .k8s directory
if input_files is not None and input_files != "":
    files = find_file(input_files, input_directory)
elif input_files is None or input_files == "":
    files = [file for file in find_recursive_files(input_directory)]

print(files)

env_vars = dict((var, os.environ[var]) for var in os.environ)

files_content = {}
# Read the content of YAML files into a dictionary
for file in files:
    with open(f"{file}", "r") as f:
        try:
            files_content[file] = f.read()

            content = files_content[file]
            vars_to_replace = re.findall("\$\{(.*)?\}", content)
            vars_to_replace =  list(set(vars_to_replace))

            for var in vars_to_replace:
                if var in env_vars:
                    content = re.sub(r'\$\{' + var + r'\}', env_vars[var], content)
            files_content[file] = content
        except Exception as e:
            print(f"Error on file {file}: {e}")

for file in files:
    file_relative_path = file
    if input_directory is not None:
        file_relative_path=file_relative_path.replace(f"{input_directory}", "")


    if output_directory is None and input_directory is not None:
        output_directory = input_directory

    output_file = f"{output_directory if output_directory is not None else ''}{file_relative_path}"

    if output_directory is not None:
        os.makedirs(os.path.dirname(output_file), exist_ok=True)  # Create the directory structure

    try:
        with open(output_file, "w") as f:
            f.write(files_content[file])
    except Exception as e:
        print(f"Error on writing file {output_file}: {e}")

    # Check if any placeholders were not substituted
    try:
        unsubstituted_placeholders = re.findall(r'\$\{[^}]+\}', files_content[file])
        if unsubstituted_placeholders:
            print(f"Error: Some placeholders were not substituted in {output_file}: Unsubstituted Placeholders:", " ".join(unsubstituted_placeholders))
            exit(1)
    except:
        continue
