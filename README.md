# demo-builder
这是一个静态html模块化构建方案。

## 下载
```
git clone https://github.com/lmtdit/demo-builder.git
```

## 使用

###初始化项目:
```
gulp init
```

###进入开发:
```
gulp 
// or 
gulp dev 
// or
gulp --e dev
```

### 发布
```
//发布到测试环境
gulp --e test

//发布到预生产环境
gulp --e pre

//发布到生产环境
gulp --e www
```

## License
MIT.