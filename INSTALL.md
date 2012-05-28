# Build Requirements
In order to build [Undo Wikipedia Blackout][], you need to have the following install [git][] 1.7+ and the latest version of [node.js][] 0.6+ (which includes [npm][]).

# Building
Follow these steps to build [Undo Wikipedia Blackout][];

1. Clone a copy of the main [Undo Wikipedia Blackout git repository](https://github.com/neocotic/UndoWikipediaBlackout) by running `git clone git://github.com/neocotic/UndoWikipediaBlackout.git`
2. `cd` to the repository directory
3. Ensure you have all of the dependencies by entering `npm install`
4. For the compiled and runnable version `cd` to the repository directory and enter `cake build`
   * Outputs to the `bin` directory
5. For the optimized distributable file enter `cake dist`
   * Outputs to the `dist` directory
   * Currently requires a `zip` utility to exist on the path
6. To update the documentation enter `cake docs`
   * Not currently working on Windows as it uses linux shell commands

To remove all built files and/or directories, run `cake clean`.

# Debugging
To run the locally built extension in [Google Chrome][] you can follow these steps;

1. Launch Google Chrome
2. Bring up the extensions management page by clicking the wrench icon ![wrench](http://code.google.com/chrome/extensions/images/toolsmenu.gif) and choosing **Tools > Extensions**
3. Ensure **Developer mode** is checked in the top right of the page
4. **Disable** all other versions of the extension which are installed to avoid any conflicts
5. Click the **Load unpacked extension...** button (a file dialog appears)
6. In the file dialog, navigate to the extension's `bin` folder (created by `cake build`) and click **OK**

[git]: http://git-scm.com
[google chrome]: http://www.google.com/chrome
[node.js]: http://nodejs.org
[npm]: http://npmjs.org
[undo wikipedia blackout]: http://neocotic.com/UndoWikipediaBlackout