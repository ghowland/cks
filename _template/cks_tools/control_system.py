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
import shutil

import template
from paper_topics import TOPICS

COMMANDS = ['list', 'show', 'build', 'scan', 'gen', 'backup', 'cleanup']

SEPARATOR_SERIES_PATH = ' → '

WORKING_DIR = '/mnt/c/Users/Geoff/cks/cks'

ZENODO_SET = '_template/cks_tools/zenodo_master_manifest.json'
PAPER_SET = 'papers.json'

GEN_PDF = './_template/_old/gen_pdf.sh'
SCAN = '../../../_template/_old/scan.py'
GEN_BIBS = './_template/_old/create_bibs.py'
README = '../../../_template/_old/readme_gen.py'

# Site
README_SITE = "_template/data/README_site.md"
README_SITE_OUT = "README_site.md"


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

    # Only do stubbed
    if item['doi']['is_stub']:
      directory = os.path.dirname(item['file_path'])
      cmd = f'{GEN_PDF} {directory}' 
      print(cmd)

      (status, output, error) = execute_command(cmd)
      print(f'  Result: {status}  Output: {output[:40]}')


def Scan(args):
  original_dir = os.getcwd()

  print("Scan papers:")
  for item in args.papers:
    os.chdir(original_dir)

    # Only do stubbed
    if item['doi']['is_stub']:
      directory = os.path.dirname(item['file_path'])
      os.chdir(directory)
      cmd = f'{SCAN}'
      print(cmd)

      # Scan
      (status, output, error) = execute_command(cmd)
      print(f'  Result: {status}  Output: {output[:40]}')

      # Gen the readme
      if status == 0:
        (status, output, error) = execute_command(README)
        if status != 0:
          print(f'  README Result: {status}  Output: {output[:40]}  Error: {error}')
  
  # Back to original dir
  os.chdir(original_dir)


def Gen(args):
  print("Generate")
  readme_site = open(README_SITE).read()

  # Flatten the list
  topic_data = []
  for topic in TOPICS:
    for key, item in topic.items():
      item['topic'] = key

      # Add papers to the topic
      item['papers'] = []
      for paper in args.papers:
        # Skip?
        if paper['skip']:
          continue

        # print(f"Sub: {paper['subject']} Top: {topic}")
        if paper['subject'] == key:
          # print(f'Added paper: {topic}: {paper}')
          if paper['key_result'] == None:
            # Take from 
            if paper['subtitle'] != None:
              paper['key_result'] = paper['subtitle']
            elif paper['abstract'] != None:
              paper['key_result'] = paper['abstract'].split('. ')[0].strip()

          item['papers'].append(paper)

      topic_data.append(item)

  # Provide topics
  data = {'topics': topic_data}

  template.render_template(README_SITE_OUT, readme_site, data)


def Backup(args):
  print("Backup")

  for item in args.papers:

    # Only do stubbed
    if item['doi']['is_stub']:
      backup = item['file_path'].replace('.md', '_orig.md')
      print(f'Backup: {item["file_path"]} -> {backup}')
      shutil.copy2(item['file_path'], backup)


def Cleanup(args):
  print("Cleanup")

  for item in args.papers:

    # Only do stubbed
    if item['doi']['is_stub']:
      print(f'Cleanup: {item["file_path"]}')

      # Get lines
      backup = item['file_path'].replace('.md', '_orig.md')
      lines = open(backup).read().split('\n')

      # Fix the special lines
      for count in range(0, len(lines)):
        line = lines[count]
        if line.startswith('# CKS-') and item['title'] in line:
          end_line = line.split(':', 1)[1].strip()
          lines[count] = f'# {end_line}'
        
        if line.startswith('**Registry:**'):
          lines[count] = f'**Registry:** {item["paper_id"]}'

      # Write the file out again
      output = '\n'.join(lines)
      with open(item['file_path'], 'w') as fp:
        fp.write(output)

      # break



def Show(args):
  print("Show something")


def Main(args):
  os.chdir(WORKING_DIR)

  args.work_list = []
  with open(ZENODO_SET, "r", encoding="utf-8") as fp:
    args.zenodo = json.load(fp)

  with open(PAPER_SET, "r", encoding="utf-8") as fp:
    args.papers = json.load(fp)

  if args.verbose:
    print(f"Verbosity is enabled.")
  
  if args.command not in COMMANDS:
    print(f'Unknown command: {args.command}')
    print('\nCommands: %s\n' % ', '.join(COMMANDS))
    exit(1)
  
  # Commands
  if args.command == 'list':
    List(args)
  elif args.command == 'show':
    Show(args)
  elif args.command == 'build':
    Build(args)
  elif args.command == 'scan':
    Scan(args)
  elif args.command == 'gen':
    Gen(args)
  elif args.command == 'backup':
    Backup(args)
  elif args.command == 'cleanup':
    Cleanup(args)

if __name__ == '__main__':
  parser = argparse.ArgumentParser(description="Control System for safely handling large counts of Zenodo papers")

  parser.add_argument("command", help="Action to perform: %s" % ', '.join(COMMANDS) )
  parser.add_argument("-n", "--name", type=str, default="User", help="The name to greet (default: User)")
  parser.add_argument("-c", "--count", type=int, default=1, help="A numeric repeat count (default: 1)")
  parser.add_argument("-v", "--verbose", action="store_true", help="Increase output verbosity")
  args = parser.parse_args()
  Main(args)


