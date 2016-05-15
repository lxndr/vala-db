include ../common.mk
NAME = db
TARGET = $(LIB_DIR)/$(NAME).$(LIBEXT)
OUTDIR = $(BUILD_DIR)/$(NAME)


PACKAGES = \
	gio-2.0 \
	gee-0.8 \
	sqlite3 \
	mysql


all: $(TARGET)
	


$(TARGET): *.vala
	$(call print_target,"Building target 'db'")
	rm -rf $(OUTDIR)
	mkdir -p $(OUTDIR)
	mkdir -p $(INCLUDE_DIR)
	mkdir -p $(VAPI_DIR)
	mkdir -p $(LIB_DIR)
	cd $(OUTDIR) && \
		valac $(FLAGS) $(foreach pkg,$(PACKAGES),--pkg=$(pkg)) --library=$(NAME) --use-header --header=$(NAME).h --vapi-comments --compile $(CURDIR)/*.vala && \
		$(AR) rcs $(TARGET) *.o
	mv $(OUTDIR)/$(NAME).h $(INCLUDE_DIR)
	mv $(OUTDIR)/$(NAME).vapi $(VAPI_DIR)
	rm -f $(BUILD_DIR)/*.o


clean:
	rm -rf $(OUTDIR)
	rm -f $(VAPI_DIR)/$(NAME).vapi
	rm -f $(INCLUDE_DIR)/$(NAME).h
	rm -f $(TARGET)

