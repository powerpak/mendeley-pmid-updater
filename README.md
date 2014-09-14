# Mendeley PMID Updater

[Mendeley](http://www.mendeley.com/) is a pretty nice reference manager that syncs to an online account (currently with 2GB of free storage).  While it imports PDFs as citable references with remarkable accuracy, and is wonderful for a cite-while-you-write workflow, it doesn't always pick up PMIDs and PMCIDs.  Certain citation styles, such as [those used by the NIH for grant proposals](http://publicaccess.nih.gov/include-pmcid-citations.htm), require you to add these IDs to your bibliography.

This little script attempts to fix that.

## Requirements

Ruby and some basic gems are required, which can be installed with Bundler.

Linux and Mac computers are supported.

The script operates locally on your Mendeley database, which is normally ends in `.sqlite`, named after your Mendeley username, and is in one of the following folders:

* Windows XP: C:\Documents and Settings\<Your Name>\Local Settings\Application Data\Mendeley Ltd\Mendeley Desktop\
* Windows Vista / Windows 7: %LOCALAPPDATA%\Mendeley Ltd.\Mendeley Desktop\
* Mac OS X: /Users/<Your username>/Library/Application Support/Mendeley Desktop/
* Linux: ~/.local/share/data/Mendeley Ltd./Mendeley Desktop/

## Usage

First, clone this repository to a directory and `cd` into it.  Then:

    bundle install
    rake

## Bonus tasks

