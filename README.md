# Immich Backup Script
Quick and dirty backup script for Unraid. Uses rsync for the actual backup.

If you're backing up over an SMB connection, make sure your mount has the following options: 

- noserverino
Tells the client not to trust the unique 64-bit “inode“ numbers the server sends.
Instead the kernel invents its own 32-bit numbers locally.
- cache=loose
Lets the client cache file data and attributes very aggressively and does not guarantee that what you read is what is actually on the server right now. Use only when a single backup will be running at a time.
- nobrl (no byte-range locks)
Turns off sending byte-range lock requests to the server. Use only when you are certain no application on the client needs real locking.
