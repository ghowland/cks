#!/usr/bin/env python3

"""
Control System for safely handling large counts of Zenodo papers
"""

import argparse
import sys

COMMANDS = ['list', 'show']


def List(args):
  print("List everything")

def Show(args):
  print("Show something")

def Main(args):
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


