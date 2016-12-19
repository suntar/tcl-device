pics = device


all: ${pics:=.png} ${pics:=.pdf}\

%.png: %.fig
	fig2dev -Lpng -j -m1.5 $< $@

%.pdf: %.fig
	fig2dev -Lpdf -m1 -j $< $@

clean:
	rm -f *.png 0*.pdf
