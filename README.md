# git-media

GitMedia extension allows you to use Git with large media files
without storing the media in Git itself.

## Configuration

Setup the attributes filter settings.

	(once after install)
	$ git config filter.media.clean "git-media filter-clean"
	$ git config filter.media.smudge "git-media filter-smudge"

Setup the `.gitattributes` file to map extensions to the filter.

	(in repo - once)
	$ echo "*.mov filter=media -crlf" > .gitattributes

Staging files with those extensions will automatically copy them to the
media buffer area (.git/media) until you run 'git media sync' wherein they
are uploaded.  Checkouts that reference media you don't have yet will try to
be automatically downloaded, otherwise they are downloaded when you sync.

Next you need to configure git to tell it where you want to store the large files.
There are five options:

1. Storing remotely in Amazon's S3
2. Storing locally in a filesystem path
3. Storing remotely via SCP (should work with any SSH server)
4. Storing remotely in atmos
5. Storing remotely via WebDav

Here are the relevant sections that should go either in `~/.gitconfig` (for global settings)
or in `clone/.git/config` (for per-repo settings).

```ini
[git-media]
	transport = <scp|local|s3|atmos|webdav>

	# settings for scp transport
	scpuser = <user>
	scphost = <host>
	scppath = <path_on_remote_server>

	# settings for local transport
	path = <local_filesystem_path>

	# settings for s3 transport
	s3bucket = <name_of_bucket>
	s3key    = <s3 access key>
	s3secret = <s3 secret key>

	# settings for atmos transport
	endpoint = <atmos server>
	uid      = <atmos_uid>
	secret   = <atmos secret key>
	tag      = <atmos object tag>

	# settings for webdav transport
	webdavurl = <webdav root url>
	webdavuser = <user for basic auth>
	webdavpassword = <password for basic auth>
	webdavverifyserver = <Net::Dav.verify_server setting, true by default>
	webdavbinarytransfer = <Net::Dav.new :curl option value, false by default>


```


## Usage

	(in repo - repeatedly)
	$ (hack, stage, commit)
	$ git media sync

You can also check the status of your media files via

	$ git media status

Which will show you files that are waiting to be uploaded and how much data
that is. If you want to upload & delete the local cache of media files, run:

	$ git media clear

## Config Settings

	$ git config --global media.auto-download false


## Installing

    $ sudo gem install trollop
    $ sudo gem install s3
    $ sudo gem install ruby-atmos-pure
    $ sudo gem install right_aws
    $ sudo gem install net_dav
    $ gem build git-media.gemspec
    $ sudo gem install git-media-0.1.3.gem

## Notes for Windows

It is important to switch off git smart newline character support for media files.
Use `-crlf` switch in `.gitattributes` (for example `*.mov filter=media -crlf`) or config option `core.autocrlf = false`.

If installing on windows, you might run into a problem verifying certificates
for S3 or something. If that happens, modify

	C:\Ruby191\lib\ruby\gems\1.9.1\gems\right_http_connection-1.2.4\lib\right_http_connection.rb

And add at line 310, right before `@http.start`:

      @http.verify_mode     = OpenSSL::SSL::VERIFY_NONE

## Copyright

Copyright (c) 2009 Scott Chacon. See LICENSE for details.
