#
# Produce plots for years 2008-2013.
#
# Note:  bzip2 compression of ETSOVista XML files is significantly better than
# that of xz.

SHELL=/bin/bash
datadir=../data2
date=$(shell date +%Y-%m-%d)

# This is broken when operating in a clean working directory:
flow_xml=$(wildcard ETSOVista-PhysicalFlow-DE-*.xml)
sched_xml=$(wildcard ETSOVista-FinalSchedules-DE-*.xml)

flow_out=$(patsubst %.xml, %.out, $(flow_xml))
sched_out=$(patsubst %.xml, %.out, $(sched_xml))
xml2=$(patsubst %.xml, %.xml2, $(flow_xml) $(sched_xml))


.PHONY: default
default: eu2013.js eu2012.js eu2011.js eu2010.js eu2009.js eu2008.js eu2007.js eu2006.js flow2013.js flow2012.js flow2011.js flow2010.js flow2009.js flow2008.js sched2013.js sched2012.js sched2011.js sched2010.js sched2009.js sched2008.js

eu%.js: post-process.pl Statistics_2004.csv
	./post-process.pl --csvfile Statistics_2004.csv --outcsv --outstem eu


flow2013.js: ETSOVista-PhysicalFlow-DE-2012-1.out ETSOVista-PhysicalFlow-DE-2013-1.out post-process.pl Statistics_2004.csv
	./post-process.pl --content flow --csvfile Statistics_2004.csv --outstem flow --outyear 2013 ETSOVista-PhysicalFlow-DE-2012-1.out ETSOVista-PhysicalFlow-DE-2013-1.out

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



sched2013.js: ETSOVista-FinalSchedules-DE-2012-1.out ETSOVista-FinalSchedules-DE-2013-1.out post-process.pl Statistics_2004.csv
	./post-process.pl --content schedules --csvfile Statistics_2004.csv --outstem sched --outyear 2013 ETSOVista-FinalSchedules-DE-2012-1.out ETSOVista-FinalSchedules-DE-2013-1.out

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



Statistics_2004.csv: Statistics.csv | $(datadir)
	@if [ -f $(datadir)/$< ] && diff -q $< $(datadir)/$< > /dev/zero; then \
		echo "$< unchanged"; \
	else \
		echo "$< changed"; \
		cp -af $< $(datadir); \
		cp -af $< $(datadir)/$<-$(date); \
		bzip2 -vf $(datadir)/$<-$(date); \
		cp -af $< $@; \
	fi


$(xml2): %.xml2: %.xml | $(datadir)
# if %.xml2 is not identical with %.xml --> update
# special case:  don't update 2010 flow because recent entsoe.net data is flawed (2012-03-24 version seems best)
	@if [ -f $@ ] && diff -q $< $@ > /dev/zero || [ "$<" == "ETSOVista-PhysicalFlow-DE-2010-1.xml" ] ; then \
		echo "$@ unchanged, not updating $@"; \
	else \
		echo "$< changed, updating $@"; \
		cp -af $< $@; \
	fi
	@if [ -f $(datadir)/$< ] && diff -q $< $(datadir)/$< > /dev/zero; then \
		echo "$(datadir)/$< unchanged"; \
	else \
		echo "$(datadir)/$< changed"; \
		cp -af $< $(datadir); \
		cp -af $< $(datadir)/$<-$(date); \
		bzip2 -vf $(datadir)/$<-$(date); \
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

$(datadir):
	mkdir -p $(datadir)


test:
	@echo home: $(HOME)
	@echo xml:  $(xml)
	@echo xml2: $(xml2)
