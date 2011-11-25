fs      = require "fs"
fs.path = require "path"
{exec, spawn} = require "child_process"

ROOT = fs.path.resolve __dirname
DEST = "#{ROOT}/build"

task "src", "compile src/ into build/javascript", (options) ->
  src options


task "html", "compile html/ into build/index.html", (options) ->
  css options
  sync "#{ROOT}/assets/", "#{DEST}/"
  html options


task "css", "sync css/ to build/css", (options) ->
  css()

task "docs", "run Docco on the files in src/", (options) ->
  exec "mkdir -p '#{DEST}'", (err) ->
    docs = fs.path.relative DEST, "#{ROOT}/src/*.coffee"
    exec "cd '#{DEST}'; docco #{docs}", (err, stdout, stderr) ->
      throw err if err?

task "demo", "compile the demo page into build/demo", (options) ->
  src options, "#{DEST}/demo/javascript"
  find "#{ROOT}/demo", "coffee", (files) ->
    brew files, o: "#{DEST}/demo"
  sync "#{ROOT}/demo/index.html", "#{DEST}/demo/index.html"


task "tests", "compile the tests (also compiles src/)", (options) ->
  exec "mkdir -p '#{DEST}/test'", (err) ->
    throw err if err?
    fs.readFile "#{ROOT}/test/index.html", "utf8", (err, html) ->
      throw err if err?
      html = insertScriptTags html, null, "#{DEST}/test/"
      fs.writeFileSync "#{DEST}/test/index.html", html, "utf8"
  
  src options
  find "#{ROOT}/test/src", "coffee", (files) ->
    brew files, {o: "#{DEST}/test", j: "suite"}
  sync "#{ROOT}/test/fixtures/", "#{DEST}/test/fixtures"
  

# Sync file and folders (recursively)
sync = (from, to) ->
  exec "rsync -ur '#{from}' '#{to}'"

# Compile CoffeeScript file(s)
brew = (files, options) ->
  files = "#{files.join "' '"}" if files instanceof Array
  args = ""
  for own key, value of options
    args += "-#{key} "
    args += "'#{value}' " if typeof value is "string"
  exec "coffee -c #{args} '#{files}'", (err, stdout, stderr) ->
    console.log err if err?
    console.log stderr if stderr


# Compile the CoffeeScript files in `src/` according to `_manifest.js`
src = (options, outdir) ->
  compilerOptions =
    o: outdir or "#{DEST}/javascript/"
  
  {files} = require "./src/_manifest.js"
  files = ("#{ROOT}/src/#{file}.coffee" for file in files)
  
  brew files, compilerOptions


css = ->
  sync "#{ROOT}/css/", "#{DEST}/css"

# Insert script-tags according to `_manifest.js`
insertScriptTags = (html, base = "#{DEST}/javascript", relativeTo = DEST) ->
  timestamp = (new Date).getTime()
  
  {files} = require "./src/_manifest.js"
  files = (fs.path.relative relativeTo, "#{base}/#{file}.js" for file in files)
  html.replace /^([ \t]*)<!--\s*scripts\s*-->/mi, (line, leading) ->
    (for file in files
      """#{leading}<script src="#{file}?#{timestamp}"></script>"""
    ).join "\n"


# Build the html
html = (options) ->
  template = fs.readFileSync "#{ROOT}/html/index.html", "utf8"
  leading = template.match(/^([ \t]*)<!--\s*body\s*-->/mi)?[1]
  throw "No placeholder found in index.html" unless leading?
  template = insertScriptTags template
  find "#{ROOT}/html/pages", "html", (files) ->
    readFiles files, (pages) ->
      for file, index in pages
        basename = fs.path.basename file.file
        pages[index] = "<!-- #{basename} -->\n#{file.contents}\n<!-- end #{basename} -->"
      pages = pages.join "\n\n"
      pages = pages.replace /^/mg, leading
      template = template.replace /<!--\s*body\s*-->/i, pages
      fs.writeFileSync "#{DEST}/index.html", template, "utf8"


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


# Asynchronous concatentation of `files`
concat = (files, callback) ->
  pending = files.length
  callback "" unless pending > 0
  result = ""
  for file in files
    fs.readFile file, "utf8", (err, contents) ->
      throw err if err?
      result += contents + "\n\n"
      --pending or callback result


# Concat `files` in order
concatSync = (files) ->
  result = ""
  for file in files
    contents = fs.readFileSync file, "utf8"
    result += contents + "\n\n"
  return result


# Walk a directory structure, collecting regular files
walk = (path, callback) ->
  files = []
  
  branch = (err, stats) ->
    if err?
      callback? err
      return
    if stats.isFile()
      callback null, [path]
    else
      fs.readdir path, reader
  
  reader = (err, names) ->
    unless pending = names.length
      callback? null, files
    for name in names
      walk fs.path.join(path, name), (err, append) ->
        if err?
          callback? err
          return
        Array::push.apply files, append
        callback? null, files if --pending is 0
  
  fs.lstat path, branch


# Same as `walk` but filtered by filename extension
find = (path, extension, callback) ->
  extension = new RegExp "\.(#{extension})$", "i"
  walk path, (err, files) ->
    throw err if err?
    files = (file for file in files when extension.test file)
    callback files

