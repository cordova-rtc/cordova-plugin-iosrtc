/**
 * Dependencies.
 */
var gulp = require('gulp'),
	jscs = require('gulp-jscs'),
	stylish = require('gulp-jscs-stylish'),
	browserify = require('browserify'),
	vinyl_source_stream = require('vinyl-source-stream'),
	jshint = require('gulp-jshint'),
	filelog = require('gulp-filelog'),
	path = require('path'),

/**
 * Constants.
 */
	PKG = require('./package.json');


gulp.task('lint', function () {
	var src = ['gulpfile.js', 'js/**/*.js', 'hooks/**/*.js'];

	return gulp.src(src)
		.pipe(filelog('lint'))
		.pipe(jshint('.jshintrc')) // enforce good practics
		.pipe(jscs('.jscsrc')) // enforce style guide
		.pipe(stylish.combineWithHintResults())
		.pipe(jshint.reporter('jshint-stylish', {verbose: true}))
		.pipe(jshint.reporter('fail'));
});


gulp.task('browserify', function () {
	return browserify([path.join(__dirname, PKG.main)], {
		standalone: 'iosrtc'
	})
		.exclude('cordova/exec')  // Exclude require('cordova/exec').
		.bundle()
		.pipe(vinyl_source_stream('iosrtc.js'))
		.pipe(filelog('browserify'))
		.pipe(gulp.dest('dist/'));
});


gulp.task('default', gulp.series('lint', 'browserify'));
