var exec = require('child_process').exec
exec("npm install", function(error, stdout, stderr) {
	if (error) throw error;

	// Include the CoffeeScript interpreter so that .coffee files will work
	var coffee = require('coffee-script');

	// Include our application file
	var app = require('./app.coffee');
});
