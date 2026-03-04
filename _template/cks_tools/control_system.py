#!/usr/bin/env python3

"""
Control System for safely handling large counts of Zenodo papers
"""

import argparse
import sys
import os
import json
import pprint
import subprocess

COMMANDS = ['list', 'show', 'build']

WORKING_DIR = '/mnt/c/Users/Geoff/cks/cks'

WORKING_PATH_SET = '_template/cks_tools/paper_work_list.txt'
ZENODO_SET = '_template/cks_tools/zenodo_master_manifest.json'
PAPER_SET = 'papers.json'


def execute_command(command, shell=True):
    """
    Executes a shell command and returns the return code, stdout, and stderr.
    
    Args:
        command (list or str): The command to run. Pass as a list if shell=False.
        shell (bool): Whether to execute through the shell. Use False for security.
        
    Returns:
        tuple: (return_code, stdout, stderr)
    """
    try:
        # We use capture_output=True to grab stdout and stderr
        # text=True returns strings instead of raw bytes
        result = subprocess.run(
            command,
            shell=shell,
            capture_output=True,
            text=True,
            check=False  # Don't raise exception on non-zero exit code
        )
        
        return result.returncode, result.stdout.strip(), result.stderr.strip()
        
    except FileNotFoundError:
        return 1, "", f"Error: Command '{command}' not found."
    except Exception as e:
        return 1, "", str(e)


def List(args):
  print("List everything")
  # print(args.work_list)
  for item in args.papers:
    if item['doi']['is_stub']:
      print(item['file_path'])
      # print(item['subject'])
      # pprint.pprint(item)
      # print(item.keys())


def Build(args):
  print("Build papers:")
  for item in args.papers:
    if item['doi']['is_stub']:
      directory = os.path.dirname(item['file_path'])
      cmd = f'./_template/_old/gen_pdf.sh {directory}' 
      print(cmd)

      (status, output, error) = execute_command(cmd)
      print(f'  Result: {status}  Output: {output[:40]}')

def Show(args):
  print("Show something")


def Main(args):
  os.chdir(WORKING_DIR)

  # Save our work list data
  # args.work_list = open(WORKING_PATH_SET).read().strip().split('\n')

  args.work_list = []
  with open(ZENODO_SET, "r", encoding="utf-8") as fp:
    args.zenodo = json.load(fp)

  with open(PAPER_SET, "r", encoding="utf-8") as fp:
    args.papers = json.load(fp)

  if args.verbose:
    print(f"Verbosity is enabled.")
  
  if args.command not in COMMANDS:
    print(f'Unknown command: {args.command}')
    exit(1)
  
  # List
  if args.command == 'list':
    List(args)
  
  # Show
  if args.command == 'show':
    Show(args)
  
  # Build
  if args.command == 'build':
    Build(args)




if __name__ == '__main__':
  parser = argparse.ArgumentParser(description="Control System for safely handling large counts of Zenodo papers")

  parser.add_argument("command", help="Action to perform: %s" % ', '.join(COMMANDS) )
  parser.add_argument("-n", "--name", type=str, default="User", help="The name to greet (default: User)")
  parser.add_argument("-c", "--count", type=int, default=1, help="A numeric repeat count (default: 1)")
  parser.add_argument("-v", "--verbose", action="store_true", help="Increase output verbosity")
  args = parser.parse_args()
  Main(args)


