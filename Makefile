SHELL=/bin/bash
data=../data2
date=$(shell date +%Y-%m-%d)
flow_xml=$(wildcard ETSOVista-PhysicalFlow-DE-*.xml)
sched_xml=$(wildcard ETSOVista-FinalSchedules-DE-*.xml)
flow_out=$(patsubst %.xml, %.out, $(flow_xml))
sched_out=$(patsubst %.xml, %.out, $(sched_xml))
xml2=$(patsubst %.xml, %.xml2, $(flow_xml) $(sched_xml))


.PHONY: default
default: net2012.js net2011.js net2010.js net2009.js net2008.js net2007.js net2006.js flow2012.js flow2011.js flow2010.js flow2009.js flow2008.js flow2007.js flow2006.js sched2012.js sched2011.js sched2010.js sched2009.js sched2008.js sched2007.js sched2006.js 

net%.js: post-process.pl Statistics_2004.csv
	./post-process.pl --csvfile Statistics_2004.csv --outcsv --outstem net

flow%.js: post-process.pl Statistics_2004.csv $(flow_out)
	./post-process.pl --content flow      --csvfile Statistics_2004.csv --outstem flow  --outyear $* ETSOVista-PhysicalFlow-DE-$*-1.out   ETSOVista-PhysicalFlow-DE-$$(($*-1))-1.out

sched%.js: post-process.pl Statistics_2004.csv $(sched_out)
	./post-process.pl --content schedules --csvfile Statistics_2004.csv --outstem sched --outyear $* ETSOVista-FinalSchedules-DE-$*-1.out ETSOVista-FinalSchedules-DE-$$(($*-1))-1.out


Statistics_2004.csv: Statistics.csv
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
	@if [ -f $@ ] && [ -f $(data)/$< ] && diff -q $< $(data)/$< > /dev/zero; then \
		echo "$< unchanged"; \
	else \
		echo "$< changed"; \
		cp -af $< $(data); \
		cp -af $< $(data)/$<-$(date); \
		bzip2 -vf $(data)/$<-$(date); \
		cp -af $< $@; \
	fi


# use .SECONDARY to avoid deleting of intermediary files
.SECONDARY: $(flow_out) $(sched_out)
%.out: %.xml2 extract.pl
	./extract.pl $< $@

Statistics.csv: Statistics.xls
	localc --headless -env:UserInstallation=file://$(HOME)/.libreoffice-cline -convert-to csv Statistics.xls

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
