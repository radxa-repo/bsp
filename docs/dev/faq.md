# Developer FAQ

## `bsp` takes a lot of time applying patches

There are 2 possible causes:

1. Your `bsp` project is stored on mechinical hard drives.  
   As patching is random 4K intensive, we suggest you put `bsp` on solid state drives.
2. Your source tree has too many dangling commits.  
   This happens naturally as you use the project. You can go to the source tree under `.src` and run `git gc --prune` to restore the performance.