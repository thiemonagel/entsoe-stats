# Statistics_2005.csv may be obtained as .xls from
# https://www.entsoe.eu/db-query/exchange/detailed-electricity-exchange/
# --> From 01/2005 to 12/2011, Output: XLS, Export Country: ALL, Import Country: ALL

SHELL=/bin/bash
data=../data2
date=$(shell date +%Y-%m-%d)
flow=$(wildcard ETSOVista-PhysicalFlow*.xml)
final=$(wildcard ETSOVista-FinalSchedules*.xml)
xml2=$(patsubst %.xml, %.xml2, $(flow) $(final))
out=$(patsubst %.xml, %.out, $(flow) $(final))

.PHONY: default
default: fdata2005.js fdata2006.js fdata2007.js fdata2008.js fdata2009.js fdata2010.js fdata2011.js 

fdata%.js: post-process.pl Statistics_2005.csv ETSOVista-FinalSchedules-DE-%-1.out ETSOVista-PhysicalFlow-DE-%-1.out
	./$^ --year $*

Statistics_2005.csv: Statistics.csv
	@mkdir -p $(data)
	@if [ -f $(data)/$< ] && diff -q $< $(data)/$< > /dev/zero; then \
		echo "$< unchanged"; \
	else \
		echo "$< changed"; \
		cp -af $< $(data); \
		cp -af $< $(data)/$<-$(date); \
		bzip2 -vf $(data)/$<-$(date); \
		cp -af $< $@; \
	fi

$(xml2): %.xml2: %.xml
	@mkdir -p $(data)
	@if [ -f $(data)/$< ] && diff -q $< $(data)/$< > /dev/zero; then \
		echo "$< unchanged"; \
	else \
		echo "$< changed"; \
		cp -af $< $(data); \
		cp -af $< $(data)/$<-$(date); \
		bzip2 -vf $(data)/$<-$(date); \
		cp -af $< $@; \
	fi


# use .SECONDARY to avoid deleting of intermediary files
.SECONDARY: $(out)
%.out: %.xml2 extract.pl
	./extract.pl $< $@

Statistics.csv: Statistics.xls
	localc --headless -env:UserInstallation=file://$(shell mktemp -d -t entso-loffice.XXXXXX) -convert-to csv Statistics.xls

Statistics_2007.csv: Statistics.csv
	@touch $@.bak
	@if diff -q $< $@.bak > /dev/zero; then \
		echo "$< unchanged"; \
	else \
		echo "$< changed"; \
		mv $< $@; \
		cp -f $@ $@.bak; \
	fi

test:
	@echo home: $(HOME)
	@echo xml:  $(xml)
	@echo xml2: $(xml2)
