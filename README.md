# upnews

[![Travis-CI Build Status](https://travis-ci.org/ginolhac/upnews.svg?branch=master)](https://travis-ci.org/ginolhac/upnews)

Display news for outdated github packages

## Motivation

Get a similar output as the RStudio **Update** button for CRAN packages, but for GitHub ones.

![](docs/cran_update.png)

## Installation

You can install the released version of upnews from [github](https://github.com/ginolhac/upnews)

### Console version

``` r
if (!requireNamespace("remotes")) install.packages("remotes")
remotes::install_github("ginolhac/upnews")
```

### With add-in

``` r
if (!requireNamespace("remotes")) install.packages("remotes")
remotes::install_github("ginolhac/upnews", dependencies = TRUE)
```

## Procedure

This add-in will fetch the remote `HEAD sha1` of local github packages and compare them, to the remote `HEAD` (same branch). 
If some packages are outdated, fetch and display a link to a NEWS file (case insensitive `NEWS.md`).

## Usage and ouput

### Console

``` r
> upnews::upnews()
fetching distant sha1
   |++++++++++++++++++++++++++++++++++++++++++++++++++| 100% elapsed = 2s
2 outdated pkgs, fetching news...
no news for jeroen/commonmark/master
# A tibble: 14 x 4
   pkgs      local                     remote       news                                                   
 * <chr>     <chr>                     <chr>        <chr>                                                  
 1 cloc      hrbrmstr/cloc@1798147)    master@b406… https://raw.…
 2 commonma… jeroen/commonmark@51dfe7… master@eda5… NA 
```

### RStudio add-in

- use the **upnews** link in the _Addins_ menu.
- in the console, a progress bar display the retrieval of remote HEAD
- finally a [`DataTable`](https://rstudio.github.io/DT/) output in the viewer is displayed such as:

![](docs/screenshot.png)

## increase limits to the GITHUB API

If you need more request to the GitHub API, you must be authenticated. Then, the limit
is **5,000** requests per hour instead of **60**.

To authenticate yourself, you can follow the great [happygitwithr](http://happygitwithr.com) bookdown by Jenny Bryan. The specific chapter about the `GITHUB_PAT` env variable is [here](http://happygitwithr.com/github-pat.html). Brefly:

- create a token with no rights on GitHub
- write this token in your `~/.Renviron` file
- from a fresh R session, check you registered token with `Sys.getenv("GITHUB_PAT")`


## TODO

- smarter search for news 
- add tests
- add travis build status
- add check buttons for **install**
- use `cli` for console output
- is it useful since `remotes` v2.0.1 allows an interactive upgrade?

