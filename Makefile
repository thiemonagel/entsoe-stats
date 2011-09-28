date=$(shell date +%m-%d)

# Statistics_2007-.csv may be obtained as .xls from
# https://www.entsoe.eu/db-query/exchange/detailed-electricity-exchange/
# --> From 01/2007 to 12/2011, Output: XLS, Export Country: ALL, Import Country: ALL
# and may be converted to .csv with LibreOffice (no editing necessary)

fdata.js: Statistics_2007-.csv 2009final.out 2010final.out 2011final.out 2011.out post-process.pl
	./post-process.pl Statistics_2007-.csv 2009final.out 2010final.out 2011final.out 2011.out

2011.out: ETSOVista-PhysicalFlow-DE-2011-1.xml extract.pl
	./extract.pl $< $@

2009final.out 2010final.out 2011final.out: %final.out: ETSOVista-FinalSchedules-DE-%-1.xml extract.pl
	./extract.pl $< $@
	cp -a ETSOVista-FinalSchedules-DE-$*-1.xml ETSOVista-FinalSchedules-DE-$*-$(date).xml
	bzip2 ETSOVista-FinalSchedules-DE-$*-$(date).xml
	mkdir -p ../data
	mv ETSOVista-FinalSchedules-DE-$*-$(date).xml.bz2 ../data
	cp -a $@ ../data/$*-$(date)final.out
