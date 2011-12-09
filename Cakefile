fs      = require "fs"
fs.path = require "path"
{exec, spawn} = require "child_process"

ROOT = fs.path.resolve __dirname
DEST = "#{ROOT}/build"

CONCAT_NAME = "nota"

# ---------------- Options

option "-c", "--concat", "Concatenate src/ files before compiling"

# ---------------- Tasks

task "src", "compile src/ into build/javascript", (options) ->
  compileSrc options


task "html", "compile html/ into build/index.html", (options) ->
  css options
  sync "#{ROOT}/assets/", "#{DEST}/"
  console.log "synced assets/ -> build/"
  html options


task "css", "sync css/ to build/css DEPRECATED", (options) ->
  css options

task "style", "compile sass/ to build/css", (options) ->
    style options

task "docs", "run Docco on the files in src/", (options) ->
  exec "mkdir -p '#{DEST}'", (err) ->
    throw err if err?
    docs = fs.path.relative DEST, "#{ROOT}/src/*.coffee"
    exec "cd '#{DEST}'; docco #{docs}", (err, stdout, stderr) ->
      if err? then throw err
      else console.log "docco'ed src/ -> /build/docs/"


task "demo", "compile the demo page (also compiles src/)", (options) ->
  options.concat = false
  invoke "src"
  find "#{ROOT}/demo", "*.coffee", (err, files) ->
    throw err if err?
    brew files, o: "#{DEST}/demo", j: "demo", ->
      console.log "compiled build/demo/demo.js"
  sync "#{ROOT}/demo/demo.html", "#{DEST}/"
  console.log "synced demo/demo.html -> build/demo.html"


task "tests", "compile the tests (also compiles src/)", (options) ->
  exec "mkdir -p '#{DEST}/test'", (err) ->
    throw err if err?
    fs.readFile "#{ROOT}/test/index.html", "utf8", (err, html) ->
      throw err if err?
      html = insertScriptTags options, html, null, "#{DEST}/test/"
      fs.writeFileSync "#{DEST}/test/index.html", html, "utf8"
      console.log "wrote build/test/index.html"
  
  invoke "src"
  
  sync "#{ROOT}/test/fixtures/", "#{DEST}/test/fixtures"
  console.log "synced test/fixtures/ -> build/test/fixtures/"
  
  find "#{ROOT}/test/src", "*.coffee", (err, files) ->
    throw err if err?
    brew files, {o: "#{DEST}/test", j: "suite"}, ->
      console.log "compiled test/src/ -> build/test/suite.js"


task "lint:html", "validate build/index.html", (options) ->
  w3c = require "./tools/support/w3c"
  w3c.validateHTML "#{DEST}/index.html"


task "lint:css", "validate css/nota.css", (options) ->
  w3c = require "./tools/support/w3c"
  find "#{ROOT}/css", "*.css", (err, files) ->
    throw err if err?
    iterator = ->
      return if files.length is 0
      file = files.pop()
      console.log "Validating #{fs.path.basename file}"
      w3c.validateCSS file, iterator
    iterator()



# ---------------- Higher-level stuff


# Compile the CoffeeScript files in `src/` according to `_manifest.js`
compileSrc = (options, outdir) ->
  compilerOptions =
    o: outdir or "#{DEST}/javascript/"
  
  compilerOptions.j = CONCAT_NAME if options.concat
  
  {files} = require "./src/_manifest.js"
  files = ("#{ROOT}/src/#{file}.coffee" for file in files)
  
  brew files, compilerOptions, ->
    console.log "compiled src/ -> #{fs.path.relative ROOT, compilerOptions.o}"


# Sync the css dir to build DEPRECATED
css = ->
  console.log "This function is deprecated and will be removed use cake style."
  exec "mkdir -p '#{DEST}'", (err) ->
    throw err if err?
    sync "#{ROOT}/css/", "#{DEST}/css"
    console.log "synced css/ -> build/css/"

# Compile sass to css
style = () ->
  exec "sass --update sass:build/css", (err) ->
    throw err if err? 
    console.log "compiled sass -> build/css"


# Build the html
html = (options) ->
  template = fs.readFileSync "#{ROOT}/html/index.html", "utf8"
  leading = template.match(/^([ \t]*)<!--\s*body\s*-->/mi)?[1]
  throw "No placeholder found in index.html" unless leading?
  template = insertScriptTags options, template
  find "#{ROOT}/html/pages", "*.html", (err, files) ->
    throw err if err?
    readFiles files, (pages) ->
      for file, index in pages
        basename = fs.path.basename file.file
        pages[index] = "<!-- #{basename} -->\n#{file.contents}\n<!-- end #{basename} -->"
      pages = pages.join "\n\n"
      pages = pages.replace /^/mg, leading
      template = template.replace /<!--\s*body\s*-->/i, pages
      fs.writeFileSync "#{DEST}/index.html", template, "utf8"
      console.log "wrote build/index.html"


# ---------------- Helpers/utils

# Compile CoffeeScript file(s)

brew = (files, options, callback) ->
  files = "#{files.join "' '"}" if files instanceof Array
  args = ""
  for own key, value of options
    args += "-#{key} "
    args += "'#{value}' " if typeof value is "string"
  exec "coffee -c #{args} '#{files}'", (err, stdout, stderr) ->
    console.log err if err?
    console.log stderr if stderr
    callback?() if not err? and not stderr


# Sync file and folders (recursively) using `rsync` 
sync = (from, to) ->
  exec "rsync -ur '#{from}' '#{to}'"


# Insert script-tags according to `_manifest.js`
insertScriptTags = (options, html, base = "#{DEST}/javascript", relativeTo = DEST) ->
  timestamp = (new Date).getTime()
  if options.concat
    files = [CONCAT_NAME]
  else
    {files} = require "./src/_manifest.js"
  files = (fs.path.relative relativeTo, "#{base}/#{file}.js" for file in files)
  html.replace /^([ \t]*)<!--\s*scripts\s*-->/mi, (line, leading) ->
    (for file in files
      """#{leading}<script src="#{file}?#{timestamp}"></script>"""
    ).join "\n"


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


# Find files in a given `dir` by a pattern (see the manpage for `find`)
find = (dir, filter, callback) ->
  exec "find '#{dir}' -name '#{filter}'", (err, stdout, stderr) ->
    if err? or stderr
      callback (err or stdout), null
    else
      callback null, (file for file in stdout.split("\n") when file)

