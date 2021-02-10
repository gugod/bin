qrcode: qrcode.pl
	pp -M Imager::File::GIF -M Imager::File::PNG -o $@ $<
