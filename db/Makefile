NAME = db
include ../common.mk
TARGET = $(LIB_DIR)/$(NAME).$(LIBEXT)


PACKAGES = \
	--pkg=gio-2.0 \
	--pkg=gee-0.8 \
	--pkg=sqlite3


all: $(TARGET)
	


$(TARGET): *.vala
	rm -rf $(_BUILD_DIR)
	mkdir -p $(_BUILD_DIR)
	mkdir -p $(INCLUDE_DIR)
	mkdir -p $(VAPI_DIR)
	mkdir -p $(LIB_DIR)
	cd $(_BUILD_DIR) && \
		valac $(FLAGS) $(PACKAGES) --library=$(NAME) --use-header --header=$(NAME).h --compile $(CURDIR)/*.vala && \
		$(AR) rcs $(TARGET) *.o
	mv $(_BUILD_DIR)/$(NAME).h $(INCLUDE_DIR)
	mv $(_BUILD_DIR)/$(NAME).vapi $(VAPI_DIR)
	rm -f $(_BUILD_DIR)/*.o


clean:
	rm -rf $(_BUILD_DIR)
	rm -f $(VAPI_DIR)/$(NAME).vapi
	rm -f $(INCLUDE_DIR)/$(NAME).h
	rm -f $(TARGET)

