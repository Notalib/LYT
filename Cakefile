fs      = require "fs"
fs.path = require "path"
{exec, spawn} = require "child_process"
{concat} = require "./tools/support/concat"

ROOT = fs.path.resolve __dirname
DEST = "#{ROOT}/build"

CONCAT_NAME = "nota"

# ---------------- Options

option "-c", "--concat", "Concatenate src/ files before compiling"

# ---------------- Tasks

task "app", "same as `cake html src sass`", (options) ->
  invoke task for task in ["src", "html", "sass"]


task "src", "compile src/ into build/javascript", (options) ->
  compileSrc options


task "html", "compile html/ into build/index.html", (options) ->
  sync "#{ROOT}/assets/", "#{DEST}/"
  console.log "synced assets/ -> build/"
  html options


task "sass", "compile sass/ into build/css", (options) ->
  style options


task "docs", "run Docco on the files in src/", (options) ->
  exec "mkdir \"#{DEST}\"", (err) ->
    throw err if err?
    files = walkSync "#{ROOT}/src", /\.coffee$/i
    docs = ("\"#{fs.path.relative DEST, file}\"" for file in files).join " "
    exec "cd \"#{DEST}\"; docco #{docs}", (err, stdout, stderr) ->
      if err? then throw err
      else console.log "docco'ed src/ -> /build/docs/"


task "tests", "compile the tests (also compiles src/)", (options) ->
  exec "mkdir \"#{DEST}/test\"", (err) ->
    throw err if err?
    compileTests()
  
  sync "#{ROOT}/test/fixtures/", "#{DEST}/test/fixtures"
  console.log "synced test/fixtures/ -> build/test/fixtures/"


task "lint:html", "validate build/index.html", (options) ->
  w3c = require "./tools/support/w3c"
  w3c.validateHTML "#{DEST}/index.html"


task "lint:css", "validate css/nota.css", (options) ->
  w3c = require "./tools/support/w3c"
  files = walkSync "#{DEST}/css", /\.css$/i
  iterator = ->
    return if files.length is 0
    file = files.pop()
    console.log "Validating #{fs.path.basename file}"
    w3c.validateCSS file, iterator
  iterator()



# ---------------- Higher-level stuff

compileSrc = (options, outdir, callback) ->
  [outdir, callback] = [null, outdir] if arguments.length is 2
  srcdir = "#{ROOT}/src"
  outdir or= "#{DEST}/javascript/"
  files = walkSync srcdir, /\.coffee$/i
  concat srcdir, files, (order, result) ->
    if options.concat
      compilerOptions =
        j: CONCAT_NAME
        o: outdir
      brew order, compilerOptions, ->
        console.log "compiled src/ -> #{fs.path.relative ROOT, outdir}"
        callback? "javascript/#{CONCAT_NAME}.js"
    else
      compilerOptions = {}
      pending = files.length
      paths = []
      for file in order
        relative = fs.path.relative srcdir, file
        paths.push relative.replace(/\.coffee$/i, '')
        compilerOptions.o = fs.path.dirname fs.path.join(outdir, relative)
        brew file, compilerOptions, ->
          pending--
          if pending <= 0
            console.log("compiled src/ -> #{fs.path.relative ROOT, outdir}")
            callback? paths


compileTests = (callback) ->
  src = (callback) ->
    srcdir  = "#{ROOT}/src"
    testsrc = "#{ROOT}/test/src"
    outdir  = "#{DEST}/test/javascript/"
    files = walkSync testsrc, /\.coffee$/i
    concat srcdir, files, (list) ->
      pending = list.length
      paths = []
      compilerOptions = {}
      for file in list
        relative = fs.path.relative ROOT, file
        paths.push relative.replace(/\.coffee$/i, '')
        compilerOptions.o = fs.path.dirname fs.path.join(outdir, relative)
        brew file, compilerOptions, ->
          pending--
          if pending <= 0
            console.log("compiled test/src/ and src/ -> #{fs.path.relative ROOT, outdir}")
            callback? paths
  
  src (paths) ->
    paths = ("javascript/#{path}.js" for path in paths)
    readFiles ["#{ROOT}/test/index.html"], (template) ->
      template = insertScriptTags paths, template.pop().contents
      fs.writeFileSync "#{DEST}/test/index.html", template, "utf8"
      console.log "compiled test/index.html -> build/test/index.html"


# Sync the css dir to build DEPRECATED
css = ->
  exec "mkdir \"#{DEST}\"", (err) ->
    throw err if err?
    sync "#{ROOT}/assets/css/", "#{DEST}/css/lib"
    console.log "synced assets/css/ -> build/css/lib/"

# Compile sass to css
style = (options) ->
  compass options, -> 
    console.log "compiled sass/ -> build/css"


# Build the html
html = (options) ->
  template = fs.readFileSync "#{ROOT}/html/index.html", "utf8"
  leading = template.match(/^([ \t]*)<!--\s*body\s*-->/mi)?[1]
  throw "No placeholder found in index.html" unless leading?
  
  grind "#{ROOT}/src", walkSync("#{ROOT}/src", /\.coffee$/i), (list) ->
    list = [CONCAT_NAME] if options.concat
    
    list = ("javascript/#{file}.js" for file in list)
    template = insertScriptTags list, template
  
    files = walkSync "#{ROOT}/html/pages", /\.html$/i
    readFiles files, (pages) ->
      for file, index in pages
        basename = fs.path.basename file.file
        pages[index] = "<!-- #{basename} -->\n#{file.contents}\n<!-- end #{basename} -->"
      pages = pages.join "\n\n"
      pages = pages.replace /^/mg, leading
      template = template.replace /<!--\s*body\s*-->/i, pages
      fs.writeFileSync "#{DEST}/index.html", template, "utf8"
      console.log "compiled html/ -> build/index.html"


# ---------------- Helpers/utils

# Compile Sass file(s)


compass = (options, callback) ->
  exec "compass compile --sass-dir \"#{ROOT}/sass\" --css-dir \"#{DEST}/css\"", (err, stdout) ->
    console.log err if err?
    console.log stdout if stdout?
    callback?() if not err?

sass = (options, callback) ->
  exec "sass --update sass:build/css", (err, stdout) ->
    throw err if err?
    callback?()


# Get relative filepaths
grind = (loadpath, files, callback) ->
  concat "#{ROOT}/src", walkSync("#{ROOT}/src", /\.coffee$/i), (list) ->
    list = (fs.path.relative(loadpath, file).replace(/\.coffee+$/i, "") for file in list)
    callback list


# Compile CoffeeScript file(s)
brew = (files, options, callback) ->
  files = "#{files.join '" "'}" if files instanceof Array
  args = ""
  for own key, value of options
    args += "-#{key} "
    args += "\"#{value}\" " if typeof value is "string"
  
  exec "coffee -c #{args} \"#{files}\"", (err, stdout, stderr) ->
    console.log err if err?
    console.log stderr if stderr
    callback?() if not err? and not stderr


# Sync file and folders (recursively) using `rsync` 
sync = (from, to) ->
  exec "rsync -ur \"#{from}\" \"#{to}\""


# Insert script tags
insertScriptTags = (files, html) ->
  timestamp = (new Date).getTime()
  html.replace /^([ \t]*)<!--\s*scripts\s*-->/mi, (line, leading) ->
    ("""#{leading}<script src="#{file}?#{timestamp}"></script>""" for file in files).join "\n"


# Read `files`
readFiles = (files, callback) ->
  pending = files.length
  files = files.slice 0
  callback files unless pending > 0
  for file, index in files
    do (file, index) -> fs.readFile file, "utf8", (err, contents) ->
      throw err if err?
      files[index] = file: file, contents: contents
      --pending or callback files


# Find files in a given `dir` by a regexp pattern
walkSync = (directory, pattern = /.*/) ->
  found = []
  items = fs.readdirSync directory
  for item in items
    item = fs.path.join directory, item
    if fs.statSync(item).isDirectory()
      found = found.concat walkSync(item, pattern)
    else if pattern.test item
      found.push item
  found

