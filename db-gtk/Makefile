include ../common.mk
NAME = db-gtk
TARGET = $(LIB_DIR)/$(NAME).$(LIBEXT)
OUTDIR = $(BUILD_DIR)/$(NAME)


PACKAGES = \
	--vapidir=$(VAPI_DIR) \
	--pkg=gee-0.8 \
	--pkg=gtk+-3.0 \
	--pkg=sqlite3 \
	--pkg=db


all: $(TARGET)
	


$(TARGET): *.vala $(VAPI_DIR)/db.vapi
	$(call print_target,"Building target 'db-gtk'")
	rm -rf $(OUTDIR)
	mkdir -p $(OUTDIR)
	mkdir -p $(INCLUDE_DIR)
	mkdir -p $(VAPI_DIR)
	mkdir -p $(LIB_DIR)
	cd $(OUTDIR) && \
		valac $(FLAGS) $(PACKAGES) --library=$(NAME) --use-header --header=$(NAME).h --Xcc="-I$(INCLUDE_DIR)" --Xcc="-DGETTEXT_PACKAGE=\"db-gtk\"" --compile $(CURDIR)/*.vala && \
		$(AR) rcs $(TARGET) *.o
	mv $(OUTDIR)/$(NAME).h $(INCLUDE_DIR)
	mv $(OUTDIR)/$(NAME).vapi $(VAPI_DIR)
	rm -f $(OUTDIR)/*.o


clean:
	rm -rf $(OUTDIR)
	rm -f $(VAPI_DIR)/$(NAME).vapi
	rm -f $(INCLUDE_DIR)/$(NAME).h
	rm -f $(TARGET)

