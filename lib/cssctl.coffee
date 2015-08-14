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
setting = require './setting'
gulp    = require 'gulp'
gutil   = require 'gulp-util'
mincss  = require 'gulp-minify-css'
plumber = require 'gulp-plumber'
Tools   = require './Tools'
color   = gutil.colors

# CSS相关设置
_cssPath        = setting.cssPath
_cssDistPath    = setting.distPath + 'css'
_mapPath        = setting.mapPath
_hashLen        = setting.hashLength
_cssMapPath     = path.join(_mapPath, setting.cssMap)
_imgMapPath     = path.join(_mapPath, setting.imgMap)


# 将css背景图替换成带hash版本标记的
_stream = (files,cb,cb2)->
    imgMap = Tools.getImgMap()
    gulp.src files
        .pipe plumber({errorHandler: Tools.errrHandler})
        .pipe mincss({
                keepBreaks:false
                compatibility:
                    properties:
                        iePrefixHack:true
                        ieSuffixHack:true
            })
        .on 'data',(source)->
            _path = source.path.replace(/\\/g,'/')
                               .split(_cssPath)[1]
            _nameObj = path.parse(_path)
            _nameObj.hash = Tools.md5(source.contents)
            _cssBgReg = /url\s*\(([^\)]+)\)/g
            _source = String(source.contents).replace _cssBgReg, (str,map)->
                if map.indexOf('fonts/') isnt -1 or map.indexOf('font/') isnt -1 or map.indexOf('#') isnt -1
                    return str
                else
                    key = map.replace('../img/', '')
                             .replace(/(^\'|\")|(\'|\"$)/g, '')
                    val = if _.has(imgMap,key) then '../img/' + imgMap[key].distname else ( if map.indexOf('data:') > -1 or map.indexOf('about:') > -1 then map else '../img/' + key + '?=t' + String(new Date().getTime()).substr(0,8) )
                    return str.replace(map, val)
            cb(_nameObj,_source)
        .on 'end',cb2

# 生成css的生产文件
_buildCss = (_filePath,source)->
    Tools.mkdirsSync(path.dirname(_filePath))
    fs.writeFileSync(_filePath, source, 'utf8')

# 生成css的Hash Map
_buildMap = (map,cb)->
    _oldMap = Tools.getJSONSync(_cssMapPath)
    _newMap = _.assign(_oldMap,map)
    jsonData = JSON.stringify _newMap, null, 2
    Tools.mkdirsSync(_mapPath)
    fs.writeFileSync(_cssMapPath, jsonData, 'utf8')
    cb()

###
# css生产文件构建函数
# @param {string} file 同gulp.src接口所接收的参数，默认是css源文件的所有css文件
# @param {function} done 回调函数
###
cssCtl = (file,done)->
    cssMap = {}
    _file = _cssPath + '**/*.css'
    if typeof file is 'function'
        _done = file
    else
        _file = file or _file
        _done = done or ->
    setting.env isnt 'dev' and gutil.log color.yellow "Push Css to dist."
    _count = 0
    _stream(
        file
        (obj,source)->
            _source = source
            _distName = obj.dir + '/' + obj.name + '.' + obj.hash.substr(0,_hashLen) + obj.ext
            _distName2 = obj.dir + '/' + obj.name + obj.ext

            cssMap[obj.base] = 
                hash : obj.hash
                distname : _distName.replace(/^\//,'')
                
            _filePath = path.join(_cssDistPath, _distName)
            _filePath2 = path.join(_cssDistPath, _distName2)
            # 生成两份css，一份覆盖式发布的，一份非覆盖式发布的，如果CDN容量有限就定期清理
            
            _buildCss _filePath,_source
            _buildCss _filePath2,_source
            _count++
        ->
            _buildMap cssMap,->
                setting.env isnt 'dev' and gutil.log color.green "#{_count} css files pushed!"
                _done()
    ) 

module.exports = cssCtl
