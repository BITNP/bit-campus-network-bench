# 校园网测试脚本

## Requirement
* Python 3.9.* 使用了Python 3.9的特有语法
* 在Linux下运行
* 安装geckodriver或者chromedriver
* 安装v2ray
* 安装v2ray[外部数据集](https://github.com/ToutyRater/V2Ray-SiteDAT/raw/master/geofiles/h2y.dat)，拷贝到`/usr/share/v2ray`下
* 推荐使用poetry管理依赖，否则请自行pip install

~~最方便的方法是装一个Archlinux~~

## Usage
```bash
bash ./run.sh {firefox,chrome}
```
