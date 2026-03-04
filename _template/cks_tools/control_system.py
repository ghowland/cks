#!/usr/bin/env python3

"""
Control System for safely handling large counts of Zenodo papers
"""

import argparse
import sys
import os
import json

COMMANDS = ['list', 'show']

WORKING_DIR = '/mnt/c/Users/Geoff/cks/cks'

WORKING_PATH_SET = '_template/cks_tools/paper_work_list.txt'
AUDIT_SET = '_template/cks_tools/zenodo_master_manifest.json'


def List(args):
  print("List everything")
  # print(args.work_list)
  print(args.zenodo)


def Show(args):
  print("Show something")


def Main(args):
  os.chdir(WORKING_DIR)

  # Save our work list data
  args.work_list = open(WORKING_PATH_SET).read().strip().split('\n')

  with open(AUDIT_SET, "r", encoding="utf-8") as fp:
    args.zenodo = json.load(fp)

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




if __name__ == '__main__':
  parser = argparse.ArgumentParser(description="Control System for safely handling large counts of Zenodo papers")

  parser.add_argument("command", help="Action to perform: %s" % ', '.join(COMMANDS) )
  parser.add_argument("-n", "--name", type=str, default="User", help="The name to greet (default: User)")
  parser.add_argument("-c", "--count", type=int, default=1, help="A numeric repeat count (default: 1)")
  parser.add_argument("-v", "--verbose", action="store_true", help="Increase output verbosity")
  args = parser.parse_args()
  Main(args)


