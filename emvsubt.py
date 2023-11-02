#!/usr/bin/python3
import os
import re
import argparse
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
    parser.error("-f | --files is required")

if input_directory is not None and not input_directory.endswith('/'):
    input_directory = input_directory + "/"
elif input_directory is None:
    input_directory = "./"


if not os.path.exists(input_directory):
    print(f"{input_directory} doesn't exists.")
    exit(1)
elif os.path.isfile(input_directory) or not os.path.isdir(input_directory):
    print(f"{input_directory} is not a directory.")
    exit(1)

current_directory = os.getcwd()
input_directory = os.path.relpath(input_directory, start=current_directory)

if output_directory is not None and not output_directory.endswith("/"):
    output_directory = output_directory + "/"

def find_file(files_input: str, input_directory: str):
    '''find files with globs'''
    files_input_array = files_input.split(',')
    fs: list[str] = []
    for fi in files_input_array:
        absolute_path = os.path.join(os.path.abspath(input_directory), "**", fi)
        files_input_array_s = [f for f in glob.glob(absolute_path, recursive=True) if os.path.isfile(f)]
        files_input_array_s = [os.path.relpath(f, start=current_directory) for f in files_input_array_s]
        fs = fs + files_input_array_s
    fs = list(set(fs))
    return fs

files = find_file(input_files, input_directory)

print(files)

env_vars = dict((var, os.environ[var]) for var in os.environ)

files_content = {}
# Read the content of YAML files into a dictionary
for file in files:
    with open(f"{file}", "r") as f:
        try:
            files_content[file] = f.read()

            content = files_content[file]
            vars_to_replace = re.findall(r'\$\{(.*)?\}', content)
            vars_to_replace = list(set(vars_to_replace))

            for var in vars_to_replace:
                if var in env_vars:
                    content = re.sub(r'\$\{' + var + r'\}', env_vars[var], content)
            files_content[file] = content
        except Exception as e:
            print(f"Error on file {file}: {e}")

for file in files:
    file_relative_path = file
    if input_directory is not None:
        file_relative_path = file_relative_path.replace(f"{input_directory}", "")

    if output_directory is None and input_directory is not None:
        output_directory = input_directory

    output_file = f"{output_directory if output_directory is not None else ''}{file_relative_path}"

    try:
        unsubstituted_placeholders = re.findall(r'\$\{[^}]+\}', files_content[file])
        if unsubstituted_placeholders:
            print(f"Error: Some placeholders were not substituted in {output_file}: Unsubstituted Placeholders:", " ".join(unsubstituted_placeholders))
        else:
            os.makedirs(os.path.dirname(output_file), exist_ok=True)
            with open(output_file, "w") as f:
                f.write(files_content[file])
    except Exception as e:
        print(f"Error with file {output_file}: {e}")
