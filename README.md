# GemStone SysAdmin Tools

## Sandboxing

With sandboxing disabled, your app will have unrestricted access to:

* File system
* Network resources
* System processes
* Other system resources

This makes sense for a system administration tool that needs to manage GemStone databases, create configuration files, and interact with system processes.

Note: Apps distributed through the Mac App Store are required to be sandboxed, so this configuration is only suitable for direct distribution outside the App Store.
