fs      = require 'fs'
path    = require 'path'
gulp    = require 'gulp'
gutil   = require 'gulp-util'
color   = gutil.colors

# 判断config.json是否存在，存在则重建
_cfgFile = path.join process.env.INIT_CWD,'config.json'
if !fs.existsSync(_cfgFile)
    gutil.log color.yellow "config.json is missing!"
    _cfg = require './lib/data/default.json'
    _cfgData = JSON.stringify _cfg, null, 4
    fs.writeFileSync _cfgFile, _cfgData, 'utf8'
    gulp.task 'default',[], ->
        gutil.log color.yellow "config.json rebuild success!"
        gutil.log color.green "Run Gulp Task again! Plz..."
    return false

setting = require './lib/setting'
build  = require './lib/build'

###
# ************* 初始化 *************
###

gulp.task 'init',->
    build.init()

###
# ************* 构建任务 *************
###

gulp.task 'init',->
    build.init()
    
gulp.task 'less',->
    build.less2css()

gulp.task 'css',->
    build.css2dist()

gulp.task 'js',->
    build.js2dist()

gulp.task 'img',->
    build.img2dist()

gulp.task 'tpl',->
    build.tpl2dist()
    # build.server()

gulp.task 'watch',->
    build.watch()

gulp.task 'server',->
    build.server()

_builder = (cb)->
    build.less2css ->
        build.img2dist ->
            build.css2dist ->
                build.js2dist ->
                    build.tpl2dist -> cb()
gulp.task 'dev',->
    build.less2css ->
        build.tpl2dist ->
            build.js2dist ->
                gulp.start ['watch','server']
                        
gulp.task 'release',->
    _startTime = (new Date()).getTime()
    _builder ->
        _endTime = (new Date()).getTime()
        gutil.log color.cyan "耗时：" + (_endTime-_startTime)/1000 + "s..."
        gutil.log color.cyan "Finished release."

gulp.task 'default',->
    if setting.env is 'dev'
        gulp.start 'dev'
    else
        gulp.start 'release'