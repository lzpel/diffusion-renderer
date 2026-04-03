PYTHON := uv run python

CKPT_INVERSE  := checkpoints/diffusion_renderer-inverse-svd
CKPT_FORWARD  := checkpoints/diffusion_renderer-forward-svd

INPUT_FRAMES  := examples/input_video_frames
OUTPUT_DELIT  := examples/output_delighting
OUTPUT_RELIT  := examples/output_relighting

.PHONY: generate run run-inverse run-forward clean

# --- 準備: モデルウェイトのダウンロード ---
generate: $(CKPT_INVERSE) $(CKPT_FORWARD)

$(CKPT_INVERSE):
	$(PYTHON) utils/download_weights.py \
		--repo_id nexuslrf/diffusion_renderer-inverse-svd \
		--local_dir $(CKPT_INVERSE)

$(CKPT_FORWARD):
	$(PYTHON) utils/download_weights.py \
		--repo_id nexuslrf/diffusion_renderer-forward-svd \
		--local_dir $(CKPT_FORWARD)

# --- 実行: サンプル動画で逆+順レンダリング ---
run: run-inverse run-forward

run-inverse: $(CKPT_INVERSE) $(INPUT_FRAMES)
	$(PYTHON) inference_svd_rgbx.py --config configs/rgbx_inference.yaml \
		inference_input_dir=$(INPUT_FRAMES) \
		inference_save_dir=$(OUTPUT_DELIT) \
		chunk_mode=first

run-forward: $(CKPT_FORWARD) $(OUTPUT_DELIT)
	$(PYTHON) inference_svd_xrgb.py --config configs/xrgb_inference.yaml \
		inference_input_dir=$(OUTPUT_DELIT) \
		inference_save_dir=$(OUTPUT_RELIT)/static_frame_rotate_light \
		use_fixed_frame_ind=true rotate_light=true lora_scale=0.0

$(INPUT_FRAMES):
	$(PYTHON) utils/dataproc_extract_frames_from_video.py \
		--input_folder=examples/videos/ \
		--output_folder=$(INPUT_FRAMES) \
		--frame_rate=6

# --- 後片付け ---
clean:
	rm -rf .venv
