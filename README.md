# deb2snap

`deb2snap` is a script that lets you quickly and easily make snaps out of existing binaries that were not written with snaps in mind.

Especially packages in the Ubuntu archive.

## Features

### Path redirection

Many programs that are built in the Ubuntu archive have hardcoded paths to data (e.g. png, xml, or plugin files) and other executables (e.g. /usr/bin/bzr instead of calling bzr).

But snaps install all program files into their own subdirectory on the system (like `/apps/foo/0/`).  So a program from the Ubuntu archive would fail to find its own files when inside a snap!

We'll fix this by **intercepting system calls** that take a path and redirecting the call to our copy of the file inside the snap.

### Dependency bundling

Snaps are monolithic bundles of software, while Debian packages use a web of dependencies.  All libraries and data that a program needs will have to be included in your snaps.  It'd be a pain to manually hunt down and bundle all those dependencies.

We'll fix this by **automatically including all dependencies** in the snap.

### 32-bit support

Snappy doesn't offer an i386 version.  And the amd64 version doesn't even ship with enough support to recognize or run a 32-bit executable.

We'll fix this by **intercepting attempts to run 32-bit executables** and running it with a bundled copy of libc6:i386 as necessary.  Just use the `--32` flag to enable support for this in your snap.

## Examples

### Setup

- First, [install an up-to-date snappy system](https://developer.ubuntu.com/snappy/install) (on real hardware if you're going to be trying the Mir examples, otherwise a virtual machine is fine).
- Then make sure you have deb2snap on your own development machine: `bzr branch lp:deb2snap`.
- And you'll probably want to connect to your snappy machine with `ssh`, especially if you're going to be running any Mir apps that will take over the screen.
- Remember to run `export LC_ALL=C.UTF-8` in your `ssh` terminal.  Ubuntu Snappy doesn't have all locales yet and ssh may have ported over your local locale setting.

### Commandline app

Let's start off with a simple commandline app.  How about fan-favorite `fortune`?

    sudo apt-get install fortune-mod
    ./deb2snap fortune

This will generate a file something like `fortune-mod_1-1.99.1-7_amd64.snap` in your current directory.  It took the snap name from the package that `fortune` belongs to as well as the version for that package.  You could override either with `-n` and `-v` respectively.

Note how we installed fortune-mod first.  `deb2snap` pulls files from your installed system.  So you'll need to first install any package you want to bundle into a snap.

Let's install that snap file and run `fortune`:

    $ sudo snappy install --allow-unauthenticated fortune-mod_1-1.99.1-7_amd64.snap
    $ fortune.fortune-mod
    Small things make base men proud.
        -- William Shakespeare, "Henry VI"

Thanks, `fortune`.

Let's be proud and base and **make the snap smaller**.  We don't *need* to include *every* dependency of `fortune`.  Some come included with Ubuntu Core for free.  Let's exclude anything that comes with Ubuntu Core 15.04 Beta 2:

    ./deb2snap -d 15.04/beta-2 fortune

If you leave off the `/beta-2`, `/release` will be assumed.

But what if we want **more fortunes**?  We can include more packages in the snap with the `-p` flag.

    ./deb2snap -d 15.04/beta-2 -p fortunes-spam -p fortunes-ubuntu-server fortune

### Non-archive app

Let's say you've got some random executable or script on your machine.  You'd like to package it up as a snap even though it didn't come from the Ubuntu archive.

That's fine!  Instead of giving the name of a program on your machine, just point `deb2snap` at the executable:

    ./deb2snap -d 15.04/beta-2 ~/Desktop/my-custom-app

`deb2snap` will automatically scan the executable and include the libraries you'll need.  But if you have any other programs or data that your app will need from the archive, you can always include them with `-p`.

Pointing at a script is especially useful if you need to do some minor setup before calling the real program.  Just remember to include the real program with `-p` in that case, since `snap2deb` won't be able to detect that automatically like usual.

### Mir app

#### Mir server snap

Mir apps need a server that has access to the input and video hardware.  For these bits, you'll need an actual physical machine (not a VM) and a Mir framework snap.

The latter is easy enough:

    bzr branch lp:~mir-team/mir/snappy-packaging
    cd snappy-packaging
    make

And you'll have a `mir` snap sitting in your current directory.  Install this on your machine and Mir will immediately start (and take over your screen!).  You should see a cursor on a black background.

You can stop and start the system compositor service like so (assuming the version of the snap is 0):

    sudo systemctl stop mir_system-compositor_0
    sudo systemctl start mir_system-compositor_0

Your app can connect to the system compositor by wrapping itself with a call to `/apps/mir/current/bin/mir-run`.  But you don't need to worry about that, `deb2snap` will do it for you.

Presumably one day a similar Mir framework will be available in the store.  But for now, you'll have to make your own.

#### Mir client snap

Once you have the Mir framework installed, let's build a simple Mir app:

    ./deb2snap -d 15.04/beta-2 --mir mir_demo_client_fingerpaint

Note the use of `--mir`.  This tells `deb2snap` that your app needs to be wrapped with a call to `/apps/mir/current/bin/mir-run` and needs to ask snappy for permission to connect to Mir.

After installing the above snap, you can run it as simply as:

    mir-demo-client-fingerpaint.mir-demos

### X app

Many apps in the Ubuntu archive still use the X protocol directly (rather than a toolkit that has been ported to Mir).  For these, we'll need to bundle Xmir into our snap.

Let's build a neat snappy demo: xfreerdp.  This will let us transform any snappy install into a thin client!

There are two versions of Xmir: the one in the archive right now which works as an extension to Xorg, and one under development that works as a separate X server called `Xmir`.  `deb2snap` has support for both, and both need a working Mir framework, as above.

The former (**Xmir Legacy**) is easier to bundle into a snap because it's in the archive already.  But it has some notable bugs: you'll have graphical glitches around your cursor, you'll see a second cursor on the screen, and you'll need to run your app as root.  Build it into your snap like so:

    ./deb2snap -d 15.04/beta-2 --xmir xfreerdp
    # copy and install snap into snappy machine
    sudo /apps/bin/xfreerdp.freerdp-x11 /f /v:SERVER /u:USER /p:PASSWORD

The latter (**Xmir Next**) is difficult to bundle in because you'll need to build it yourself (see below).  But it fixes the above bugs.

    ./deb2snap -d 15.04/beta-2 --xmir-binary ~/Xmir xfreerdp
    # copy and install snap into snappy machine
    xfreerdp.freerdp-x11 /f /v:SERVER /u:USER /p:PASSWORD

#### Building Xmir Next

    git clone git://people.freedesktop.org/~mlankhorst/xserver
    cd xserver
    sudo apt-get build-dep xorg-server
    debian/rules build
    cp ./build-main/hw/xmir/Xmir ~/

Hopefully it will be in the archive soon.

## How it works

### libsnappypreload.so

This is the library shim that does the actual interception.  We'll wrap your program in a tiny shell that sets LD_PRELOAD to point at this.

There are some clever things this library does, including intercepting execve calls to ensure that subprocesses also LD_PRELOAD libsnappypreload.so, no matter what happened to the environment in the mean time.

### Pulling in system packages

The whole point of this script is to let you run already-compiled code.  It can pull in files from installed debs and copy them into the snap.  It will find all Depends and Recommends and include them too.

This pulls from the debs installed **on your system**!  So you have to have all the packages you want to include in the snap installed.

## Common options

* -d 15.04/beta-2

  The version of Ubuntu Core you want to target.  It will skip including any package already provided by that version of Ubuntu Core.  If you leave off the '/beta-2' bit, '/release' will be assumed.

* -p PACKAGE

  An additional package to include in the snap.  All Depends and Recommends will be included too.  This can be used multiple times.

* -n NAME

  Names the snap.

* -v VERSION

  Versions the snap.

* --overlay DIRECTORY

  A directory to copy over the snap directory right before building the snap.  This lets you specify complicated meta/ files or include custom files in specific locations.  Any instances of @PACKAGE@, @VERSION@, or @ARCH@ will be replaced with the correct value before going into the snap.

* --mir

  Uses a mir wrapper script so that your executable will connect to a running Mir server.

* --xmir BINARY

  Uses an xmir wrapper script so that your executable will connect to a running Mir server through xmir and will package Xorg and xmir into your snap for you.  This will use an unconfined AppArmor template and require running the app as root.  Even then, there will be some bugs and oddities.

* --xmir-binary

  Like `--xmir` but specifies an Xmir server executable that you've built and will use that instead of Xorg.  Can be used fully confined.

* --aa-template TEMPLATE

  The AppArmor template to use.  For example, 'unconfined'.

* --vendor "NAME &lt;EMAIL&gt;"

  Your name and email.

* --desc "DESCRIPTION"

  What the package does.  Defaults to a short description from the Ubuntu archive.

* --32

  Include a copy of libc6:i386 and a 32-bit compatible version of libsnappypreload.so so that 32-bit executables will run.

* --arch

  The architecture for the snap you want to create.  Defaults to your system architecture.  You only need to specify this if you are including only multiarch packages.

## Caveats

It would be fair to describe `deb2snap` as a pile of hacks.  The tricks it uses for path redirection and 32-bit support are not ideal.  The long term fix for both would be using something like overlayfs.  But that's not ready *today* for Ubuntu Snappy so here we are.

Additionally, there are some known bugs:

* `postinst` scripts are not run.  Any archive package that needs to do some post-installation setup (like compile gsettings schemas or generate caches) may not work as expected.

* It's very likely that not every single syscall that takes a path is intercepted.  If your app needs one of the calls that we don't intercept, your files may not be found.  Please report any instance of this!
