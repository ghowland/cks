#!/usr/bin/env python3

"""
Control System for safely handling large counts of Zenodo papers
"""

import argparse
import sys

COMMANDS = ['list', 'show']

def Main(args):
  if args.verbose:
      print(f"Verbosity is enabled.")
      print(f"Positional argument value: {args.input}")

  # Example of using the numeric argument
  result = args.count * 2
  if args.verbose:
      print(f"Calculation result (count * 2): {result}")




if __name__ == '__main__':
  parser = argparse.ArgumentParser(description="Control System for safely handling large counts of Zenodo papers")

  parser.add_argument("command", help="Action to perform: ^s" )
  parser.add_argument("-n", "--name", type=str, default="User", help="The name to greet (default: User)")
  parser.add_argument("-c", "--count", type=int, default=1, help="A numeric repeat count (default: 1)")
  parser.add_argument("-v", "--verbose", action="store_true", help="Increase output verbosity")
  args = parser.parse_args()
  Main(args)


