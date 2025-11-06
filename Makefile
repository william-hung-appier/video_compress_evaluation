SHELL := /bin/bash
MATERIALS_DIR := $(CURDIR)/materials
OUT_DIR := $(CURDIR)/out

FORMAT ?= csv
THREADS_COUNT ?= 0
VERBOSE ?= false

PREFIX ?= prod
CUSTOM_W ?=
CUSTOM_H ?=


# [FORMAT] "prefix:width:height"
# Empty width/height means no scaling needed
BATCH_VIDEO_CONFIGS := \
	prod:: \
	prod1:: \
	prod2:: \
	prod3:: \
	prod4:: \
	720x1280:: \
	bad:1080:1920

get-score:
	@./scripts/get_vmaf_score.sh \
		COMPRESS=$(PREFIX)_compress.mp4 \
		ORIGIN=$(PREFIX)_origin.mp4 \
		FORMAT=$(FORMAT) \
		THREADS=$(THREADS_COUNT) \
		OUT_DIR=$(OUT_DIR) \
		PREFIX=$(PREFIX) \
		CUSTOM_W=$(CUSTOM_W) \
		CUSTOM_H=$(CUSTOM_H) \
		VERBOSE=$(VERBOSE)

get-all-scores:
	@for config in $(BATCH_VIDEO_CONFIGS); do \
		IFS=':' read -r prefix width height <<< "$$config"; \
		\
		if [ -n "$$width" ] && [ -n "$$height" ]; then \
			$(MAKE) get-score PREFIX=$$prefix CUSTOM_W=$$width CUSTOM_H=$$height; \
		else \
			$(MAKE) get-score PREFIX=$$prefix; \
		fi; \
		echo ""; \
	done
	@echo "======================================"
	@echo "Done!"

get-meta:
	@./scripts/get_video_meta.sh \
		PREFIX=$(PREFIX) \
		MATERIALS_DIR=$(MATERIALS_DIR)

get-all-meta:
	@for config in $(BATCH_VIDEO_CONFIGS); do \
		IFS=':' read -r prefix width height <<< "$$config"; \
		$(MAKE) get-meta PREFIX=$$prefix; \
		echo "---"; \
		echo ""; \
	done
	@echo "======================================"
	@echo "Done!"


extract-frame:
	@if [ -z "$(FRAME_NUM)" ]; then \
		echo "Usage: make extract-frame FRAME_NUM=875 [VIDEO=compressed]"; \
		exit 1; \
	fi
	@VIDEO_TYPE=$${VIDEO:-compressed}; \
	if [ "$$VIDEO_TYPE" = "compressed" ]; then \
		VIDEO_FILE=$(TARGET_VIDEO); \
	else \
		VIDEO_FILE=$(REFERENCE_VIDEO); \
	fi; \
	ffmpeg -i $$VIDEO_FILE \
		-vf "select=eq(n\,$(FRAME_NUM))" \
		-vframes 1 \
		$(OUT_DIR)/frame_$${VIDEO_TYPE}_$(FRAME_NUM).png; \
	echo "Saved frame $(FRAME_NUM) to $(OUT_DIR)/frame_$${VIDEO_TYPE}_$(FRAME_NUM).png"

extract-frame-pair:
	@if [ -z "$(FRAME_NUM)" ]; then \
		echo "Usage: make extract-frame-pair FRAME_NUM=875"; \
		exit 1; \
	fi
	@$(MAKE) extract-frame FRAME_NUM=$(FRAME_NUM) VIDEO=compressed
	@$(MAKE) extract-frame FRAME_NUM=$(FRAME_NUM) VIDEO=origin

clean:
	rm -rf $(OUT_DIR)
