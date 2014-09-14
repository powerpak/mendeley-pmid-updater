# Mendeley PMID Updater

[Mendeley](http://www.mendeley.com/) is a pretty nice reference manager that syncs to an online account (currently with 2GB of free storage).  While it imports PDFs as citable references with remarkable accuracy, and is wonderful for a cite-while-you-write workflow, it doesn't always pick up PMIDs and PMCIDs.  Certain citation styles, such as [those used by the NIH for grant proposals](http://publicaccess.nih.gov/include-pmcid-citations.htm), require you to add these IDs to your bibliography.

This little script attempts to fix that.  It scans your Mendeley database for journal articles and does the following:

1. If the PMID is available, it is used to retrieve the PMCID and DOI.
2. If there is no PMID, but the DOI is available, it is used to retrieve the PMCID and DOI.

The [PMC ID Converter API](http://www.ncbi.nlm.nih.gov/pmc/tools/id-converter-api/) and [EUtils](http://www.ncbi.nlm.nih.gov/books/NBK25501/) are used to try to match your IDs, in that respective order.

## Fair Warning

**Read this carefully.** Although this tool is fairly paranoid and backs up your Mendeley database before touching it—every time it runs, as a separate file into `backups/`, *even* on dry runs when no data will be written—it does operate outside of Mendeley's public APIs for accessing your data.  It *could* very well blow away your database or overwrite it in ways that you do not like.  At some point I may rewrite this to use [Mendeley's API](http://dev.mendeley.com/slate/) so that it works on your online account's data, but that would require me to set up OAuth2 and a whole lot of Not Fun things, so no go for now.

If losing data concerns you, and it should, backup your Mendeley library before using this.  You can do this by running Mendeley and looking in the `Help` menu for `Create Backup...`

The script operates locally on your Mendeley database, which is normally ends in `.sqlite`, is named after your Mendeley username, and will be found in one of the following folders:

* Mac OS X: /Users/<Your username>/Library/Application Support/Mendeley Desktop/
* Linux: ~/.local/share/data/Mendeley Ltd./Mendeley Desktop/

When you make a backup as previously described, Mendeley hands you a ZIP archive of this folder, which will also include all the files for your imported articles.  This script simply copies the `.sqlite` file into a `backups` folder before it does anything.

## Requirements

Linux and Mac computers are supported.  You'll need Ruby and some basic gems, which will be installed with Bundler.

## Usage

First, clone this repository to a directory and `cd` into it.  Then:

    $ bundle install

to install the required gems.  Of the gems needed, Nokogiri is probably the most troublesome to install, so you may need to refer to [its installation instructions](http://nokogiri.org/tutorials/installing_nokogiri.html) if it hands you an error about required libraries.  Then:

    $ rake

will perform a dry-run of the matching procedure.  If everything goes well, you will see the script start running through journal articles in your Mendeley database, reporting if it can cross-match them using the aforementioned APIs.  If it looks like it is doing a good job, then:

    $ rake update_ids

will start saving these IDs to your Mendeley database.

These tasks will not run unless Mendeley is shut down, and every time it runs, you will first see a new `.sqlite` file backed up to the `backups/` folder in this repo, just in case something goes horribly wrong.  In the rare event that this occurs, remove the numerical prefix and copy it back to the appropriate folder listed in the [Fair Warning](#fair-warning) section of this README.

The next time you start Mendeley, you will see your new DOIs, PMIDs, and PMCIDs, and it will automatically sync them to your online account, so your other computers will receive these IDs too.

If you want to use a citation that prints these IDs after your references in your bibliography, check out [this CSL](http://csl.mendeley.com/styles/100600971/national-library-of-medicine-grant-proposals-7).  You can install it for Mendeley Desktop by going to View > Citation Style > Journal Abbreviations ... changing to the Get More Styles tab, and pasting the URL at the bottom.

## License

The MIT License (MIT)

Copyright (c) 2014 Theodore Pak

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.