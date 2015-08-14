###*
# 将CSS的debug文件push到生产目录，并将引用到的背景图片自动添加hash后缀
# @date 2014-12-2 15:10:14
# @author pjg <iampjg@gmail.com>
# @link http://pjg.pw
# @version $Id$
###

fs      = require 'fs'
path    = require 'path'
_       = require 'lodash'
gulp    = require 'gulp'
gutil   = require 'gulp-util'
uglify  = require 'uglify-js'
plumber = require 'gulp-plumber'
Tools   = require './Tools'
setting = require './setting'
color   = gutil.colors

# JS相关设置
_jsPath     = setting.jsPath
_jsDistPath = setting.distPath + 'js'
_mapPath    = setting.mapPath
_hashLen    = setting.hashLength
_jsMapPath  = path.join(_mapPath, setting.jsMap)
_imgMapPath = path.join(_mapPath, setting.imgMap)
_env         = setting.env

jsImgRegex = /staticPath\s*\+\s*(('|")[\s\S]*?(.jpg|.png|.gif)('|"))/g


# 将js中引用到的图片替换成带hash版本标记的
_stream = (files,cb,cb2)->

    gulp.src files
        .pipe plumber({errorHandler: Tools.errrHandler})
        .on 'data',(res)->
            imgMap = Tools.getImgMap()
            _minCode = uglify.minify(res.contents.toString(),{fromString: true})
            _code = _minCode.code
            _source = _code.replace jsImgRegex,(str,map)->
                console.log map
                key = map.replace(/(^\'|\")|(\'|\"$)/g, '')
                         .replace('/img/', '')
                val = if _.has(imgMap,key) and _env isnt 'dev' then imgMap[key].distname else ( if map.indexOf('data:') > -1 or map.indexOf('about:') > -1 then map else key + '?=t' + String(new Date().getTime()).substr(0,8) )
                _str = str.replace(key, val)
                console.log _str
                return _str
            # console.log _source
            _path = res.path.replace(/\\/g,'/')
                            .split(_jsPath)[1]
            _nameObj = path.parse(_path)
            _nameObj.hash = Tools.md5(_source)
            cb(_nameObj,_source)
        .on 'end',cb2

# 写入文件
_buildJs = (file,source)->
    Tools.mkdirsSync(path.dirname(file))
    fs.writeFileSync(file, source, 'utf8')

# 生成Hash Map
_buildMap = (map,cb)->
    _oldMap = Tools.getJSONSync(_jsMapPath)
    _newMap = _.assign(_oldMap,map)
    jsonData = JSON.stringify _newMap, null, 2
    Tools.mkdirsSync(_mapPath)
    fs.writeFileSync(_jsMapPath, jsonData, 'utf8')
    cb()

###
# js生产文件构建函数
# @param {string} file 同gulp.src接口所接收的参数，默认是css源文件的所有css文件
# @param {function} done 回调函数
###
jsCtl = (file,done)->
    jsMap = {}
    _file = _jsPath + '**/*.js'
    if typeof file is 'function'
        _done = file
    else
        _file = file or _file
        _done = done or ->
    setting.env isnt 'dev' and gutil.log color.yellow "Push js to dist."
    _count = 0
    _stream(
        _file
        (obj,source)->
            _source = source
            _distName = obj.dir + '/' + obj.name + '.' + obj.hash.substr(0,_hashLen) + obj.ext
            _distName2 = obj.dir + '/' + obj.name + obj.ext

            jsMap[obj.base] = 
                hash : obj.hash
                distname : _distName.replace(/^\//,'')
                
            _filePath = path.join(_jsDistPath, _distName)
            _filePath2 = path.join(_jsDistPath, _distName2)

            # 生成两份js，一份覆盖式发布的，一份非覆盖式发布的，如果CDN容量有限就定期清理
            _buildJs _filePath,_source
            _buildJs _filePath2,_source
            _count++
        ->
            _buildMap jsMap,->
                setting.env isnt 'dev' and gutil.log color.green "#{_count} javascript files pushed!"
                _done()
    ) 

module.exports = jsCtl
