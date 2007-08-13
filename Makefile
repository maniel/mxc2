RBUIC=rbuic4
RBRCC=rbrcc
UIFILE=mxc2.ui
QRCFILE=mxc2.qrc
RM=rm

all: resources gui

gui:
	$(RBUIC) $(UIFILE) > ui_mxc2.rb

resources:
	$(RBRCC) $(QRCFILE) -compress 9 -o res_mxc2.rb

clean:
	$(RM) ui_mxc2.rb res_mxc2.rb
