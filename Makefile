#
# Produce plots for years 2008-2012.
#


SHELL=/bin/bash
data=../data2
date=$(shell date +%Y-%m-%d)
flow_xml=$(wildcard ETSOVista-PhysicalFlow-DE-*.xml)
sched_xml=$(wildcard ETSOVista-FinalSchedules-DE-*.xml)
flow_out=$(patsubst %.xml, %.out, $(flow_xml))
sched_out=$(patsubst %.xml, %.out, $(sched_xml))
xml2=$(patsubst %.xml, %.xml2, $(flow_xml) $(sched_xml))


.PHONY: default
default: net2012.js net2011.js net2010.js net2009.js net2008.js net2007.js net2006.js flow2012.js flow2011.js flow2010.js flow2009.js flow2008.js sched2012.js sched2011.js sched2010.js sched2009.js sched2008.js 

net%.js: post-process.pl Statistics_2004.csv
	./post-process.pl --csvfile Statistics_2004.csv --outcsv --outstem net


flow2012.js: ETSOVista-PhysicalFlow-DE-2011-1.out ETSOVista-PhysicalFlow-DE-2012-1.out post-process.pl Statistics_2004.csv 
	./post-process.pl --content flow --csvfile Statistics_2004.csv --outstem flow --outyear 2012 ETSOVista-PhysicalFlow-DE-2011-1.out ETSOVista-PhysicalFlow-DE-2012-1.out

flow2011.js: ETSOVista-PhysicalFlow-DE-2010-1.out ETSOVista-PhysicalFlow-DE-2011-1.out post-process.pl Statistics_2004.csv 
	./post-process.pl --content flow --csvfile Statistics_2004.csv --outstem flow --outyear 2011 ETSOVista-PhysicalFlow-DE-2010-1.out ETSOVista-PhysicalFlow-DE-2011-1.out

flow2010.js: ETSOVista-PhysicalFlow-DE-2009-1.out ETSOVista-PhysicalFlow-DE-2010-1.out post-process.pl Statistics_2004.csv 
	./post-process.pl --content flow --csvfile Statistics_2004.csv --outstem flow --outyear 2010 ETSOVista-PhysicalFlow-DE-2009-1.out ETSOVista-PhysicalFlow-DE-2010-1.out

flow2009.js: ETSOVista-PhysicalFlow-DE-2008-1.out ETSOVista-PhysicalFlow-DE-2009-1.out post-process.pl Statistics_2004.csv 
	./post-process.pl --content flow --csvfile Statistics_2004.csv --outstem flow --outyear 2009 ETSOVista-PhysicalFlow-DE-2008-1.out ETSOVista-PhysicalFlow-DE-2009-1.out

flow2008.js: ETSOVista-PhysicalFlow-DE-2007-1.out ETSOVista-PhysicalFlow-DE-2008-1.out post-process.pl Statistics_2004.csv 
	./post-process.pl --content flow --csvfile Statistics_2004.csv --outstem flow --outyear 2008 ETSOVista-PhysicalFlow-DE-2007-1.out ETSOVista-PhysicalFlow-DE-2008-1.out



sched2012.js: ETSOVista-FinalSchedules-DE-2011-1.out ETSOVista-FinalSchedules-DE-2012-1.out post-process.pl Statistics_2004.csv 
	./post-process.pl --content schedules --csvfile Statistics_2004.csv --outstem sched --outyear 2012 ETSOVista-FinalSchedules-DE-2011-1.out ETSOVista-FinalSchedules-DE-2012-1.out

sched2011.js: ETSOVista-FinalSchedules-DE-2010-1.out ETSOVista-FinalSchedules-DE-2011-1.out post-process.pl Statistics_2004.csv 
	./post-process.pl --content schedules --csvfile Statistics_2004.csv --outstem sched --outyear 2011 ETSOVista-FinalSchedules-DE-2010-1.out ETSOVista-FinalSchedules-DE-2011-1.out

sched2010.js: ETSOVista-FinalSchedules-DE-2009-1.out ETSOVista-FinalSchedules-DE-2010-1.out post-process.pl Statistics_2004.csv 
	./post-process.pl --content schedules --csvfile Statistics_2004.csv --outstem sched --outyear 2010 ETSOVista-FinalSchedules-DE-2009-1.out ETSOVista-FinalSchedules-DE-2010-1.out

sched2009.js: ETSOVista-FinalSchedules-DE-2008-1.out ETSOVista-FinalSchedules-DE-2009-1.out post-process.pl Statistics_2004.csv 
	./post-process.pl --content schedules --csvfile Statistics_2004.csv --outstem sched --outyear 2009 ETSOVista-FinalSchedules-DE-2008-1.out ETSOVista-FinalSchedules-DE-2009-1.out

sched2008.js: ETSOVista-FinalSchedules-DE-2007-1.out ETSOVista-FinalSchedules-DE-2008-1.out post-process.pl Statistics_2004.csv 
	./post-process.pl --content schedules --csvfile Statistics_2004.csv --outstem sched --outyear 2008 ETSOVista-FinalSchedules-DE-2007-1.out ETSOVista-FinalSchedules-DE-2008-1.out



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
