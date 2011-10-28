# LYT uses Coffeescript
Compile coffescript using the following command from the webroot.
	
	$ coffee --compile --watch  --output ./compiled ./coffee
	
	
# Refactoring notes/ideas
- Refactor setSettings to receive an array of settings to be updated
- Create CoffeeScript classes for fileinterface, settings and player and adopt a more object oriented like code structuring
- Gui has some control elements, maybe it should not
- Investigate "Refused to apply inline style because of Content-Security-Policy." warning
