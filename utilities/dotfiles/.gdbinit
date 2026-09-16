# Minimal chooser: set GDB_PLUGIN=gef|pwndbg|peda to load a plugin explicitly

# IMPORTANT:
# 1. Backup default .gdbinit
#     cp -v ~/.gdbinit ~/.gdbinit.backup.$(date +%Y%m%d_%H%M%S)
# 2. Adjust the plugins paths as needed
# 3. Copy the plugin wrappers (e.g for pwndbg https://github.com/80h3m14n/red-team-tools/blob/main/utilities/gdb-pwndbg )

# USAGE:
# gdb                # GDB without plugins
# gdb-gef /bin/ls    # GDB_PLUGIN=gef gdb
# gdb-pwndbg /bin/ls # GDB_PLUGIN=pwndbg gdb
# gdb-peda /bin/ls   # GDB_PLUGIN=peda gdb

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

