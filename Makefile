PROGRAM = Brow
IMPORTER = Importer
DISTDIR = ./dist
DEPSDIR = ./deps
BUILDDIR = ./build
BINARIES = /tmp/$(PROGRAM).dst
DMGFILE = $(PROGRAM).dmg
PRODUCT = $(DISTDIR)/$(PROGRAM).pkg
COMPONENT1 = $(DEPSDIR)/$(PROGRAM)Component.pkg
COMPONENT2 = $(DEPSDIR)/$(IMPORTER)Component.pkg
COMPONENT1_PFILE = $(PROGRAM).plist
COMPONENT2_PFILE = $(IMPORTER).plist
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
             $(COMPONENT1_PFILE) $(COMPONENT2_PFILE) \
             $(COMPONENT1) $(COMPONENT2) $(DISTRIBUTION_FILE)
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

$(COMPONENT1_PFILE) :
	@echo "Error: Missing component pfile."
	@echo "Create a component pfile with make compfiles."
	@exit 1

$(COMPONENT2_PFILE) :
	@echo "Error: Missing component pfile."
	@echo "Create a component pfile with make compfiles."
	@exit 1

$(COMPONENT1) : $(BINARIES) $(COMPONENT1_PFILE)
	pkgbuild --identifier $(IDENTIFIER) \
  --root $(BINARIES) \
  --component-plist $(COMPONENT1_PFILE) \
  $(COMPONENT1) \
  --sign GAW7W6LTYG

$(COMPONENT2) : $(BINARIES) $(COMPONENT2_PFILE)
	pkgbuild --identifier $(IDENTIFIER) \
  --root $(BINARIES) \
  --component-plist $(COMPONENT2_PFILE) \
  $(COMPONENT2) \
  --sign GAW7W6LTYG


$(DISTRIBUTION_FILE) :
	@echo "Error: Missing distribution file."
	@echo "Create a distribution file with make distfiles."
	@exit 1

.PHONY : distfiles
distfiles : $(COMPONENT1)
	productbuild --synthesize \
  --product $(REQUIREMENTS) \
  --package $(COMPONENT1) \
  $(DISTRIBUTION_FILE).new
	@echo "Edit the $(DISTRIBUTION_FILE).new template to create a suitable $(DISTRIBUTION_FILE) file."

.PHONY : compfiles
compfiles : $(BINARIES)
	pkgbuild --analyze \
  --root $(BINARIES) \
  $(COMPONENT1_PFILE).new
	@echo "Edit the $(COMPONENT1_PFILE).new template to create a suitable $(COMPONENT1_PFILE) file."

.PHONY : clean
clean :
	-rm -f $(DMGFILE) $(PRODUCT) $(COMPONENT1) $(COMPONENT2)
	-rm -rf $(BINARIES)
	-rm -rf $(BUILDDIR)

.PHONY : distclean
distclean :
	-rm -f $(DISTRIBUTION_FILE) $(DISTRIBUTION_FILE).new

.PHONY : compclean
compclean :
	-rm -f $(COMPONENT1_PFILE) $(COMPONENT1_PFILE).new
