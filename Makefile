PROGRAM = Brow
DISTDIR = ./dist
DEPSDIR = ./deps
BINARIES = /tmp/$(PROGRAM).dst
DMGFILE = $(PROGRAM).dmg
PRODUCT = $(DISTDIR)/$(PROGRAM).pkg
COMPONENT = $(DEPSDIR)/$(PROGRAM)Component.pkg
COMPONENT_PFILE = $(PROGRAM).plist
DISTRIBUTION_FILE = distribution.xml
REQUIREMENTS = requirements.plist
IDENTIFIER = com.timschroeder.Brow

.PHONY : all
all : $(DISTDIR) $(DEPSDIR) $(PRODUCT) $(DMGFILE)

$(DISTDIR) :
	mkdir $(DISTDIR)

$(DEPSDIR) :
	mkdir $(DEPSDIR)

$(PRODUCT) : $(BINARIES) $(REQUIREMENTS) \
             $(COMPONENT_PFILE) \
             $(COMPONENT) $(DISTRIBUTION_FILE)
	productbuild --distribution $(DISTRIBUTION_FILE) \
    --resources . \
    --sign GAW7W6LTYG \
    --package-path $(DEPSDIR) \
    $(PRODUCT)

$(BINARIES) :
	xcodebuild install

$(DMGFILE) :
	hdiutil create \
  -volname $(PROGRAM) \
  -srcfolder $(DISTDIR) \
  -ov \
  $(PROGRAM).dmg

$(COMPONENT_PFILE) :
	@echo "Error: Missing component pfile."
	@echo "Create a component pfile with make compfiles."
	@exit 1

$(COMPONENT) : $(BINARIES) $(COMPONENT_PFILE)
	pkgbuild --identifier $(IDENTIFIER) \
  --root $(BINARIES) \
  --component-plist $(COMPONENT_PFILE) \
  $(COMPONENT) \
  --sign GAW7W6LTYG

$(DISTRIBUTION_FILE) :
	@echo "Error: Missing distribution file."
	@echo "Create a distribution file with make distfiles."
	@exit 1

.PHONY : distfiles
distfiles : $(COMPONENT)
	productbuild --synthesize \
  --product $(REQUIREMENTS) \
  --package $(COMPONENT) \
  $(DISTRIBUTION_FILE).new
	@echo "Edit the $(DISTRIBUTION_FILE).new template to create a suitable $(DISTRIBUTION_FILE) file."

.PHONY : compfiles
compfiles : $(BINARIES)
	pkgbuild --analyze \
  --root $(BINARIES) \
  $(COMPONENT_PFILE).new
	@echo "Edit the $(COMPONENT_PFILE).new template to create a suitable $(COMPONENT_PFILE) file."

.PHONY : clean
clean :
	-rm -f $(DMGFILE) $(PRODUCT) $(COMPONENT)
	-rm -rf $(BINARIES)

.PHONY : distclean
distclean :
	-rm -f $(DISTRIBUTION_FILE) $(DISTRIBUTION_FILE).new

.PHONY : compclean
compclean :
	-rm -f $(COMPONENT_PFILE) $(COMPONENT_PFILE).new
