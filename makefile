
OUTPUT = mk mkc \
         mkd \
         mkrun mks mkt mkr \
         mklog \
         mkm \

all:
	@echo "Usage: make [install | clean]"

clean:
	rm -fv *~

install:
	@echo -e "\e[32;1minstall ${OUTPUT}\e[0m"
	mkdir -pv ~/bin/
	for file in ${OUTPUT} ; do ln -svf `pwd`/$$file ~/bin/; done
	@echo -e "\e[32;1minstall ${OUTPUT} ---> succ\e[0m"
