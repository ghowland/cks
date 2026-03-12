#!/bin/sh

 python3 _template/cks_tools/audit_paper.py --papers-dir ./ ; ./_template/cks_tools/control_system.py cleanup ; ./_template/cks_tools/control_system.py gen


 ./_template/cks_tools/control_system.py scan

 ./_template/cks_tools/control_system.py build

