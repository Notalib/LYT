fs      = require "fs"
fs.path = require "path"
w3cjs   = require "w3cjs"

# # Configuration

config =
  concatName:    "lyt"       # Name of concatenated script, when using the --concat option
  coffee:        "coffee"    # Path to CoffeeScript compiler (if not in PATH)
  docco:         "docco"     # Path to docco (if not in PATH)
  compass:       "compass"   # Path to compass (if not in PATH)
  minify:        "uglifyjs2" # Path to minifier
  maxHtmlErrors: 1           # Only "Bad value X-UA-Compatible for attribute http-equiv on element meta." is accepted

# --------------------------------------

# # Options/Switches

option "-c", "--concat",      "Concatenate CoffeeScript"
option "-m", "--minify",      "Concatenate CoffeeScript and then minify"
option "-v", "--verbose",     "Be more talkative"
option "-d", "--development", "Use development settings"
option "-t", "--test",        "Use test environment"
option "-n", "--no-validate", "Don't validate build"

# --------------------------------------

# # Tasks

task "app", "Same as `cake assets src html scss`", (options) ->
  invoke task for task in ["assets", "src", "html", "scss"]

task "assets", "Sync assets to build", (options) ->
  sync "assets", "build", (copied) -> boast "synced", "assets", "build"

task "src", "Compile CoffeeScript source", (options) ->
  invoke "notabs"
  cleanDir "build/javascript"
  files = coffee.grind "src", null, (file) ->
    if options.development
      return true
    else
      return not file.match /config.dev.coffee$/

  coffee.brew files, "src", "build/javascript", (options.concat or options.minify), ->
    boast "compiled", "src", "build/javascript"

task "html", "Build HTML", (options) ->
  createDir "build"

  template = html.readFile "html/index.html"

  pages = glob "html/pages", /\.html$/i
  pages.sort()
  body = (for page in pages
    path = "pages/#{fs.path.basename page}"
    content = "<!-- Begin file: #{path} -->\n#{html.readFile page}\n<!-- End file: #{path} -->"
  ).join "\n\n"
  template = html.interpolate template, body, 'cake:body'

  # Using config.concatName below for the css files is a little off, since
  # the sheet lyt.css is the theme roller generated sheet whereas screen.css
  # (which isn't minified) is our own.
  stylesheet = "css/#{config.concatName}.css"
  scripts = []

  if options.test
    scripts.push "http://test.e17.dk/getnotaauthtoken"
  else
    scripts.push "http://e17.dk/getnotaauthtoken"

  if options.minify
    scripts.push "javascript/#{config.concatName}.min.js"
    stylesheet = "css/#{config.concatName}.min.css"
  else if options.concat
    scripts.push "javascript/#{config.concatName}.js"
  else
    coffeeScripts = coffee.grind "src", null, (file) ->
      if options.development
        return true
      else
        return not file.match /config.dev.coffee$/
    scripts = scripts.concat(coffee.filter coffeeScripts, "src", "javascript")

  template = html.interpolate template, (html.styleSheets [stylesheet, 'css/screen.css']), 'cake:stylesheets'
  template = html.interpolate template, html.scriptTags(scripts), "cake:scripts"

  fs.writeFile "build/index.html", template, (err) ->
    throw err if err?
    boast "rendered", "html", "build/index.html"
    unless options['no-validate']
      w3cjs.validate
        file: 'build/index.html'
        callback: (res) ->
          if res.messages?.length > 0
            console.warn "There were #{res.messages.length} HTML validation error messages:"
            console.warn ''
            console.warn '<line>, <column>: <message>'
            for message in res.messages
              console.warn "#{message.lastLine}, #{message.lastColumn}: #{message.message}"
            if res.messages.length > config.maxHtmlErrors
              throw 'Refusing to continue build: it seems that the number of errors has increased'


task "scss", "Compile scss source", (options) ->
  createDir "build/css"
  scss.compile "scss", "build/css", options, ->
    boast "compiled", "scss", "build/css"


task "docs", "Run Docco on src/*.coffee", (options) ->
  cleanDir "build/docs"
  files = glob "src", /\.coffee$/i
  docco.parse files, "build", ->
    index = docco.index "build/docs"
    fs.writeFileSync "build/docs/index.html", index
    boast "docco'd", "src", "build/docs"


task "tests", "Compile the test suite", (options) ->
  cleanDir "build/test/javascript"
  files = coffee.grind "test/src", "src"
  coffee.brew files, ".", "build/test/javascript", false, ->
    boast "compiled", "test/src", "build/test/javascript"
    template = html.readFile "test/index.html"
    scripts = coffee.filter files, ".", "javascript"
    scripts = html.scriptTags scripts
    template = html.interpolate template, scripts, "scripts"
    fs.writeFile "build/test/index.html", template, (err) ->
      throw err if err?
      boast "rendered", "test/index.html", "build/test/index.html"
      sync "test/fixtures", "build/test/fixtures", (copied) ->
        boast "synced", "test/fixtures", "build/test/fixtures"


task "clean", "Remove the build dir", ->
  removeDir "build"
  boast "removed", "build"

task 'notabs', 'Make sure the coffescript files are tab free', (options) ->
  errors = checkForTabs()
  if errors
    console.error "Can't build: coffeescript contains tabs:\n" + errors
    process.exit 1

# --------------------------------------

# # CoffeeScript Support

coffee = do ->
  # ### Privileged methods
  # -----------------
  {exec} = require "child_process"

  # Group files by their directory
  group = (files, base) ->
    grouped = {}
    for file in files
      dir = fs.path.relative base, fs.path.dirname(file)
      grouped[dir] or= []
      grouped[dir].push file
    grouped

  # Compile some CoffeeScript files
  # Will *always* produce both concatenated and minified
  # versions if concat is true.
  compile = (files, output, concat, callback) ->
    cmd = "#{config.coffee} --compile"
    cmd += " --join #{concat}.js" if concat
    files = q(files).join " "
    cmd += " --output #{q output} #{files}"
    exec cmd, (err, stdout, stderr) ->
      throw err if err?
      console.log stderr if stderr
      if concat
        process.chdir output
        exec "#{config.minify} --source-map #{concat}.map -o #{concat}.min.js #{concat}.js"
        process.chdir '..'
      callback()

  # ### Public methods
  # ---------------

  # Return a list of files in their concatenation order
  grind: (directory, loadpaths, fileFilter) ->
    {grind} = require "lyt-grinder"
    loadpaths or= directory
    fileFilter or= -> true
    files = (glob directory, /\.coffee$/i).filter fileFilter
    grind loadpaths, files

  # Compile some CoffeeScript files
  # Will always produce both concatenated and minified
  # versions if concat is true.
  brew: (files, base, output, concat, callback) ->
    base   = base
    output = output

    throw "No files to compile" unless files.length

    if concat
      compile files, output, config.concatName, callback
    else
      pending = 0
      for dir, files of group(files, base)
        pending++
        dir = fs.path.join output, dir
        compile files, dir, false, ->
          --pending or callback()

  # Kinda hard to explain
  filter: (files, base, relpath = "") ->
    {join, relative} = fs.path
    base = base
    files = (join relpath, relative(base, file) for file in files)
    (file.replace /\.coffee$/i, ".js" for file in files)


# --------------------------------------

# # Coffeescript validation

checkForTabs = ->
  result = null
  for path in glob 'src', /\.coffee$/
    file = fs.readFileSync path, 'utf8'
    if match = file.match(/^.*\t.*$/m)
      result += "#{path}: #{match[0]}\n"
  return result

# --------------------------------------

# # HTML Support

html = do ->
  # Read a file into memory
  readFile: (path) ->
    path = resolve path
    fs.readFileSync path, "utf8"

  # Replace a placeholder in the template with the given string
  interpolate: (template, string, placeholder) ->
    pattern = new RegExp "^([ \\t]*)<!--\\s*#{placeholder}\\s*-->", "mi"
    template.replace pattern, (line, lead) ->
      string.replace /^/mg, lead

  # Generate script tags for the given urls
  scriptTags: (urls) ->
    urls = [urls] if typeof urls is "string"
    ("""<script src="#{url}"></script>""" for url in urls).join "\n"

  styleSheets: (urls) ->
    urls = [urls] if typeof urls is "string"
    ("""<link rel="stylesheet" type="text/css" href="#{url}">""" for url in urls).join "\n"


# --------------------------------------

# # SCSS Support

scss = do ->
  # Compile scss files in the given dir using compass
  compile: (dir, output, options, callback) ->
    {exec} = require "child_process"
    exec "#{config.compass} compile #{if options.minify then '--output-style compressed' else ''} --sass-dir #{q dir} --css-dir #{q output}", (err, stdout, stderr) ->
      fatal err, config.compass, "You may need to install compass. See http://compass-style.org/" if err?
      console.log stderr if stderr
      callback?()

# --------------------------------------

# # Docco Support

docco = do ->
  # Run the docco command on some files
  parse: (files, output, callback) ->
    {exec} = require "child_process"
    files = ("#{q resolve(file)}" for file in files).join " "
    exec "#{config.docco} #{files}", cwd: resolve(output), (err, stdout, stderr) ->
      fatal err, config.docco, "You may need to install docco via npm. See http://jashkenas.github.com/docco/" if err?
      callback?()

  # Create an index.html file to go with the docco'd html files
  index: (dir, relpath = "") ->
    {join, basename} = fs.path
    links = (for file in glob dir, /\.html$/i
      file = join relpath, basename(file)
      """\t\t<a href="#{file}">#{file.replace /\.html$/, ""}</a>"""
    )
    "<html>\n\t<body>\n#{links.join "\n"}\n\t</body>\n</html>"


# --------------------------------------

# # Low-Level Support

# Brag to the user about something you just did
boast = (verb, from, to) ->
  padR = (string, length) ->
    string = "#{string} " while string.length < length
    string

  padL = (string, length) ->
    string = " #{string}" while string.length < length
    string

  msg = "#{padL verb, 10}  #{from}"
  msg = "#{padR msg, 30} -> #{to}" if to
  console.log msg


# Is the verbose option set?
isVerbose = ->
  args = process.argv
  args.indexOf("-v") isnt -1 or args.indexOf("--verbose") isnt -1


# Quote a string so it can be used in a terminal
q = (string) ->
  if typeof string is "string"
    string = string.replace /\n/, '\\n'
    string = string.replace /\r/, '\\r'
    return string if /^\s*".*"\s*$/.test string
    "\"#{string}\""
  else
    q item for item in string


# Report an fatal error
fatal = (err, command, message) ->
  cmdError = /command failed/i.test err.message
  if cmdError
    console.error "Error: Could not run command `#{command}`"
    console.error message if message
    unless isVerbose()
      console.error "Run the cake task again with the -v/--verbose option, to see error details"
  throw err if isVerbose() or not cmdError
  process.exit 1


# A simple file synchronizer (like rsync)
# Only syncs file that don't exist or are out of date in the destination
sync = (from, to, callback) ->
  {dirname, relative, join} = require "path"
  {lstatSync, createReadStream, createWriteStream, existsSync} = require "fs"

  files = glob from, /^[^.]/i
  directories = {}

  for file in files
    dir = dirname(file)
    dir = join to, relative(from, dir)
    directories[dir] or= true

  createDir dir for own dir of directories

  queue = (for file in files
    dest = join to, relative(from, file)
    file: file
    dest: dest
  )

  copy = (op, callback) ->
    # Only copy if dest file is missing or older than source
    if existsSync(op.dest)
      willCopy = lstatSync(op.file).mtime.getTime() > lstatSync(op.dest).mtime.getTime()
    else
      willCopy = yes

    if willCopy
      stream = createReadStream op.file
      stream.pipe createWriteStream(op.dest, flags: "w")
      stream.on "end", -> callback true
    else
      callback false

  copied = 0
  next = (didCopy = false) ->
    copied++ if didCopy
    if queue.length is 0
      callback? copied
      return
    copy queue.pop(), next

  next()


# Cross-platform function for resolving a path
resolve = (relativePath) ->
  segments = relativePath.split /\+/
  segments.unshift fs.path.resolve(__dirname) unless /^(\/|[a-z]:\\)/i.test relativePath
  fs.path.join segments...


# Recursively create directories as needed
createDir = (path) ->
  return if fs.existsSync path
  segments = path.split /\/|[\\]/
  path = ""
  created = false
  until segments.length is 0
    path = fs.path.join path, segments.shift()
    continue if fs.existsSync path
    fs.mkdir path
    created = true
  boast "mkdir", path


# Remove a directory (whether it's empty or not) in the CWD
removeDir = (path) ->
  if /^\./.test fs.path.relative(__dirname, path)
    console.error "Error: Won't remove directories outside of the project"
    process.exit 1
  return unless fs.existsSync path
  cleanDir path
  fs.rmdirSync path


# Create or empty the directory specified by `path`
cleanDir = (path) ->
  path = path
  unless fs.existsSync(path)
    createDir path
    return
  files = fs.readdirSync path
  for file in files
    file = fs.path.join path, file
    if fs.lstatSync(file).isDirectory()
      removeDir file
    else
      fs.unlinkSync file


# Gather all regular files in the given directory and its sub-directories
walk = (directory) ->
  directory = resolve directory
  files = []
  for file in fs.readdirSync directory
    file = fs.path.join directory, file
    stats = fs.lstatSync file
    if stats.isDirectory()
      files = files.concat walk(file)
    else if stats.isFile()
      files.push file
  files


# Same as `walk` but the the files filtered by a regular expression
glob = (directory, pattern) ->
  (file for file in walk(directory) when pattern.test fs.path.basename(file))

