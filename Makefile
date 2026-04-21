VERSION  := 0.1.0
PKG_NAME := tsm
DEB_DIR  := packaging/debian
DEB_BIN  := $(DEB_DIR)/usr/local/bin

.PHONY: all install uninstall deb clean

all: install

install:
	@bash install.sh

uninstall:
	@bash uninstall.sh

# Build a .deb package (requires dpkg-deb)
deb: $(DEB_BIN)/$(PKG_NAME)
	dpkg-deb --build $(DEB_DIR) $(PKG_NAME)_$(VERSION)_all.deb
	@echo "Built: $(PKG_NAME)_$(VERSION)_all.deb"

$(DEB_BIN)/$(PKG_NAME): bin/$(PKG_NAME)
	mkdir -p $(DEB_BIN)
	cp bin/$(PKG_NAME) $(DEB_BIN)/$(PKG_NAME)
	chmod 755 $(DEB_BIN)/$(PKG_NAME)

clean:
	rm -f *.deb
	rm -f $(DEB_BIN)/$(PKG_NAME)
