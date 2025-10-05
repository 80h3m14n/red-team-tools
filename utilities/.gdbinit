# Minimal chooser: set GDB_PLUGIN=gef|pwndbg|peda to load a plugin explicitly

# Backup default .gdbinit
# cp -v ~/.gdbinit ~/.gdbinit.backup.$(date +%Y%m%d_%H%M%S)

# Usage
# gdb # without plugins
# gdb-gef /bin/ls # for gef
# gdb-pwndbg /bin/ls # for pwndbg 
# gdb-peda /bin/ls # for peda

python
import os,gdb
plugin = os.getenv('GDB_PLUGIN')
if not plugin:
    pass
elif plugin == 'gef':
    gdb.execute('source ~/.gef-2025.01.py')
elif plugin == 'pwndbg':
    gdb.execute('source /usr/local/lib/pwndbg-gdb/gdbinit.py')
elif plugin == 'peda':
    gdb.execute('source ~/peda/peda.py')
else:
    gdb.write('Unknown GDB_PLUGIN: %s\\n' % plugin)
end

# Restore old configurations
# cp -v ~/.gdbinit.backup.* ~/.gdbinit   # pick the file printed by the backup command earlier

