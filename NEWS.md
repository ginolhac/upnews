## version 0.1.1

### Features

* install selected packages in gadget table
    * with / without dependencies (pkgs in `Suggests` field)
* add refresh button to reload the app
* add local and remote versions from DESCRIPTION file and last commit date (#2)
* add popup on mouse over events:
    + column 1: package name (repo), popup: "user/repo"
    + column 2: local version (DESCRIPTION), popup: "ref@/sha1"
    + column 3: remote version (DESCRIPTION), popup: "ref@/sha1"
    

### Bug fix

* clicks on links don't trigger the row selection

## version 0.1

* Add a shiny gadget as add-in
* Added a `NEWS.md` file to track changes to the package.
