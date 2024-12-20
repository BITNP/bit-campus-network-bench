FROM archlinux
RUN echo 'Server = http://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist
RUN pacman -Syu --noconfirm python python-pip firefox geckodriver v2ray wget
RUN wget -O /usr/share/v2ray/h2y.dat https://github.com/ToutyRater/V2Ray-SiteDAT/raw/master/geofiles/h2y.dat
COPY requirements.txt config.json docker-run.sh test.py /app/
WORKDIR /app
RUN pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple && pip install -r requirements.txt
CMD ["/bin/bash", "docker-run.sh"]

