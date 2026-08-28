#pragma once

#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/texture2d.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>

using namespace godot;

class MenuOptimizer : public RefCounted
{
	GDCLASS(MenuOptimizer, RefCounted);

	Dictionary texture_cache;

protected:
	static void _bind_methods();

public:
	MenuOptimizer();
	~MenuOptimizer();

	String test();

	// Share the same persistent Dictionary that main_menu.gd stores
	// on /root/GameSettings.
	void set_texture_cache(Dictionary cache);

	// Complete native title/subtitle pipeline:
	// load -> get_image -> RGBA8 -> checkerboard cleanup -> ImageTexture.
	Ref<Texture2D> load_menu_texture(
		String texture_path,
		double brightness_threshold = 0.72,
		double neutral_tolerance = 0.16
	);

	// Complete native UI pipeline:
	// load -> get_image -> RGBA8 -> background cleanup -> fringe cleanup
	// -> optional largest component -> optional crop -> ImageTexture.
	Ref<Texture2D> load_clean_ui_texture(
		String texture_path,
		bool crop_transparent_margins = false,
		int fringe_passes = 8,
		double min_brightness = 0.40,
		double neutral_tolerance = 0.16
	);

	// Lightweight runtime sprite path for already-transparent PNGs.
	// Uses the shared cache without doing per-pixel cleanup.
	Ref<Texture2D> load_runtime_texture(String texture_path);

	void remove_baked_checkerboard_background(
		Ref<Image> image,
		double brightness_threshold = 0.72,
		double neutral_tolerance = 0.16
	);

	void remove_outer_white_background(Ref<Image> image);

	void remove_white_fringe(
		Ref<Image> image,
		int passes = 3,
		double min_brightness = 0.55,
		double neutral_tolerance = 0.16
	);

	void keep_largest_opaque_component(Ref<Image> image);
};
