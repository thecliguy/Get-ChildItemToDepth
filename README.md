# Get-ChildItemToDepth
Traverses a path recursively to a specified depth.

# Get-ChildItemToDepth
Traverses a path recursively to a specified depth.

DESCRIPTION
------------
This function acts as a wrapper around `Get-ChildItem`, facilitating recursive traversal of a path to a specific depth.

EXAMPLE USAGE
-------------
Recursively iterate any path matching `"C:\Program*"` up to four directories deep, returning only DLL files.

```powershell
Get-ChildItemToDepth -Path "C:\Program*" -Depth 4 -Filter "*.dll" -File
```

FURTHER READING
---------------
I wrote a blog post to accompany the first release of these script, see 
[Recursive Directory Traversal to a Specific Depth in PowerShell](https://www.thecliguy.co.uk/2020/04/29/recursive-directory-traversal-to-a-specific-depth-in-powershell/).
