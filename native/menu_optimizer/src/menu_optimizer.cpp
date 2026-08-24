#include "menu_optimizer.h"

#include <godot_cpp/classes/image_texture.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/rect2i.hpp>
#include <godot_cpp/variant/vector2i.hpp>

#include <algorithm>
#include <cstdint>
#include <vector>

namespace
{
	static inline double brightest_channel(const Color &color)
	{
		return std::max(
			static_cast<double>(color.r),
			std::max(
				static_cast<double>(color.g),
				static_cast<double>(color.b)
			)
		);
	}

	static inline double darkest_channel(const Color &color)
	{
		return std::min(
			static_cast<double>(color.r),
			std::min(
				static_cast<double>(color.g),
				static_cast<double>(color.b)
			)
		);
	}

	static inline bool is_baked_checkerboard_pixel(
		const Color &color,
		double brightness_threshold,
		double neutral_tolerance
	)
	{
		if (color.a <= 0.01)
		{
			return true;
		}

		const double brightest = brightest_channel(color);
		const double darkest = darkest_channel(color);
		const double spread = brightest - darkest;

		return (
			brightest >= brightness_threshold
			&& spread <= neutral_tolerance
		);
	}

	static inline bool is_outer_white_pixel(const Color &color)
	{
		if (color.a <= 0.01)
		{
			return true;
		}

		const double brightest = brightest_channel(color);
		const double darkest = darkest_channel(color);
		const double spread = brightest - darkest;

		return darkest >= 0.72 && spread <= 0.10;
	}
}

MenuOptimizer::MenuOptimizer()
{
}

MenuOptimizer::~MenuOptimizer()
{
}

void MenuOptimizer::_bind_methods()
{
	ClassDB::bind_method(
		D_METHOD("test"),
		&MenuOptimizer::test
	);

	ClassDB::bind_method(
		D_METHOD("set_texture_cache", "cache"),
		&MenuOptimizer::set_texture_cache
	);

	ClassDB::bind_method(
		D_METHOD(
			"load_menu_texture",
			"texture_path",
			"brightness_threshold",
			"neutral_tolerance"
		),
		&MenuOptimizer::load_menu_texture,
		DEFVAL(0.72),
		DEFVAL(0.16)
	);

	ClassDB::bind_method(
		D_METHOD(
			"load_clean_ui_texture",
			"texture_path",
			"crop_transparent_margins",
			"fringe_passes",
			"min_brightness",
			"neutral_tolerance"
		),
		&MenuOptimizer::load_clean_ui_texture,
		DEFVAL(false),
		DEFVAL(8),
		DEFVAL(0.40),
		DEFVAL(0.16)
	);

	ClassDB::bind_method(
		D_METHOD(
			"remove_baked_checkerboard_background",
			"image",
			"brightness_threshold",
			"neutral_tolerance"
		),
		&MenuOptimizer::remove_baked_checkerboard_background,
		DEFVAL(0.72),
		DEFVAL(0.16)
	);

	ClassDB::bind_method(
		D_METHOD(
			"remove_outer_white_background",
			"image"
		),
		&MenuOptimizer::remove_outer_white_background
	);

	ClassDB::bind_method(
		D_METHOD(
			"remove_white_fringe",
			"image",
			"passes",
			"min_brightness",
			"neutral_tolerance"
		),
		&MenuOptimizer::remove_white_fringe,
		DEFVAL(3),
		DEFVAL(0.55),
		DEFVAL(0.16)
	);

	ClassDB::bind_method(
		D_METHOD(
			"keep_largest_opaque_component",
			"image"
		),
		&MenuOptimizer::keep_largest_opaque_component
	);
}

String MenuOptimizer::test()
{
	return "Silent City C++ Menu Optimizer Works!";
}

void MenuOptimizer::set_texture_cache(Dictionary cache)
{
	texture_cache = cache;
}

Ref<Texture2D> MenuOptimizer::load_menu_texture(
	String texture_path,
	double brightness_threshold,
	double neutral_tolerance
)
{
	if (texture_path.is_empty())
	{
		return Ref<Texture2D>();
	}

	if (texture_cache.has(texture_path))
	{
		Ref<Texture2D> cached = texture_cache[texture_path];
		if (cached.is_valid())
		{
			return cached;
		}
	}

	Ref<Texture2D> source_texture =
		ResourceLoader::get_singleton()->load(texture_path);

	if (source_texture.is_null())
	{
		return Ref<Texture2D>();
	}

	Ref<Image> image = source_texture->get_image();

	if (image.is_null() || image->is_empty())
	{
		texture_cache[texture_path] = source_texture;
		return source_texture;
	}

	if (image->get_format() != Image::FORMAT_RGBA8)
	{
		image->convert(Image::FORMAT_RGBA8);
	}

	remove_baked_checkerboard_background(
		image,
		brightness_threshold,
		neutral_tolerance
	);

	Ref<ImageTexture> transparent_texture =
		ImageTexture::create_from_image(image);

	if (transparent_texture.is_null())
	{
		return source_texture;
	}

	Ref<Texture2D> result = transparent_texture;
	texture_cache[texture_path] = result;
	return result;
}

Ref<Texture2D> MenuOptimizer::load_clean_ui_texture(
	String texture_path,
	bool crop_transparent_margins,
	int fringe_passes,
	double min_brightness,
	double neutral_tolerance
)
{
	if (texture_path.is_empty())
	{
		return Ref<Texture2D>();
	}

	const String cache_key =
		String("ui_clean::")
		+ texture_path
		+ "::"
		+ (crop_transparent_margins ? "crop" : "keep");

	if (texture_cache.has(cache_key))
	{
		Ref<Texture2D> cached = texture_cache[cache_key];
		if (cached.is_valid())
		{
			return cached;
		}
	}

	Ref<Texture2D> source_texture =
		ResourceLoader::get_singleton()->load(texture_path);

	if (source_texture.is_null())
	{
		return Ref<Texture2D>();
	}

	Ref<Image> image = source_texture->get_image();

	if (image.is_null() || image->is_empty())
	{
		return source_texture;
	}

	if (image->get_format() != Image::FORMAT_RGBA8)
	{
		image->convert(Image::FORMAT_RGBA8);
	}

	remove_outer_white_background(image);

	remove_white_fringe(
		image,
		fringe_passes,
		min_brightness,
		neutral_tolerance
	);

	if (crop_transparent_margins)
	{
		keep_largest_opaque_component(image);

		const Rect2i used_rect = image->get_used_rect();

		if (used_rect.size.x > 0 && used_rect.size.y > 0)
		{
			image = image->get_region(used_rect);
		}
	}

	Ref<ImageTexture> cleaned_texture =
		ImageTexture::create_from_image(image);

	if (cleaned_texture.is_null())
	{
		return source_texture;
	}

	Ref<Texture2D> result = cleaned_texture;
	texture_cache[cache_key] = result;
	return result;
}

void MenuOptimizer::remove_baked_checkerboard_background(
	Ref<Image> image,
	double brightness_threshold,
	double neutral_tolerance
)
{
	if (image.is_null() || image->is_empty())
	{
		return;
	}

	const int width = image->get_width();
	const int height = image->get_height();

	if (width <= 0 || height <= 0)
	{
		return;
	}

	const int total_pixels = width * height;

	std::vector<uint8_t> visited(
		static_cast<size_t>(total_pixels),
		0
	);

	std::vector<Vector2i> queue;
	queue.reserve(static_cast<size_t>(total_pixels / 4));

	auto try_queue = [&](int x, int y)
	{
		if (x < 0 || y < 0 || x >= width || y >= height)
		{
			return;
		}

		const int index = y * width + x;

		if (visited[static_cast<size_t>(index)] != 0)
		{
			return;
		}

		visited[static_cast<size_t>(index)] = 1;

		const Color color = image->get_pixel(x, y);

		if (
			is_baked_checkerboard_pixel(
				color,
				brightness_threshold,
				neutral_tolerance
			)
		)
		{
			queue.emplace_back(x, y);
		}
	};

	for (int x = 0; x < width; ++x)
	{
		try_queue(x, 0);

		if (height > 1)
		{
			try_queue(x, height - 1);
		}
	}

	for (int y = 0; y < height; ++y)
	{
		try_queue(0, y);

		if (width > 1)
		{
			try_queue(width - 1, y);
		}
	}

	size_t queue_index = 0;

	while (queue_index < queue.size())
	{
		const Vector2i point = queue[queue_index++];

		image->set_pixel(
			point.x,
			point.y,
			Color(0.0, 0.0, 0.0, 0.0)
		);

		try_queue(point.x - 1, point.y);
		try_queue(point.x + 1, point.y);
		try_queue(point.x, point.y - 1);
		try_queue(point.x, point.y + 1);
	}
}

void MenuOptimizer::remove_outer_white_background(Ref<Image> image)
{
	if (image.is_null() || image->is_empty())
	{
		return;
	}

	const int width = image->get_width();
	const int height = image->get_height();

	if (width <= 0 || height <= 0)
	{
		return;
	}

	const int total_pixels = width * height;

	std::vector<uint8_t> visited(
		static_cast<size_t>(total_pixels),
		0
	);

	std::vector<Vector2i> queue;
	queue.reserve(static_cast<size_t>(total_pixels / 4));

	auto try_queue = [&](int x, int y)
	{
		if (x < 0 || y < 0 || x >= width || y >= height)
		{
			return;
		}

		const int index = y * width + x;

		if (visited[static_cast<size_t>(index)] != 0)
		{
			return;
		}

		visited[static_cast<size_t>(index)] = 1;

		if (is_outer_white_pixel(image->get_pixel(x, y)))
		{
			queue.emplace_back(x, y);
		}
	};

	for (int x = 0; x < width; ++x)
	{
		try_queue(x, 0);

		if (height > 1)
		{
			try_queue(x, height - 1);
		}
	}

	for (int y = 0; y < height; ++y)
	{
		try_queue(0, y);

		if (width > 1)
		{
			try_queue(width - 1, y);
		}
	}

	size_t queue_index = 0;

	while (queue_index < queue.size())
	{
		const Vector2i point = queue[queue_index++];

		image->set_pixel(
			point.x,
			point.y,
			Color(0.0, 0.0, 0.0, 0.0)
		);

		try_queue(point.x - 1, point.y);
		try_queue(point.x + 1, point.y);
		try_queue(point.x, point.y - 1);
		try_queue(point.x, point.y + 1);
	}
}

void MenuOptimizer::remove_white_fringe(
	Ref<Image> image,
	int passes,
	double min_brightness,
	double neutral_tolerance
)
{
	if (image.is_null() || image->is_empty())
	{
		return;
	}

	const int width = image->get_width();
	const int height = image->get_height();

	if (width <= 0 || height <= 0)
	{
		return;
	}

	passes = std::max(passes, 0);

	const Vector2i offsets[8] = {
		Vector2i(-1, -1),
		Vector2i(0, -1),
		Vector2i(1, -1),
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(-1, 1),
		Vector2i(0, 1),
		Vector2i(1, 1)
	};

	for (int pass = 0; pass < passes; ++pass)
	{
		std::vector<Vector2i> pixels_to_clear;

		pixels_to_clear.reserve(
			static_cast<size_t>(
				std::max(1, width * height / 16)
			)
		);

		for (int y = 0; y < height; ++y)
		{
			for (int x = 0; x < width; ++x)
			{
				const Color color = image->get_pixel(x, y);

				if (color.a <= 0.01)
				{
					continue;
				}

				const double brightest = brightest_channel(color);
				const double darkest = darkest_channel(color);
				const double spread = brightest - darkest;

				if (
					brightest < min_brightness
					|| spread > neutral_tolerance
				)
				{
					continue;
				}

				bool touches_transparency = false;

				for (const Vector2i &offset : offsets)
				{
					const int nx = x + offset.x;
					const int ny = y + offset.y;

					if (
						nx < 0
						|| ny < 0
						|| nx >= width
						|| ny >= height
					)
					{
						touches_transparency = true;
						break;
					}

					if (image->get_pixel(nx, ny).a <= 0.01)
					{
						touches_transparency = true;
						break;
					}
				}

				if (touches_transparency)
				{
					pixels_to_clear.emplace_back(x, y);
				}
			}
		}

		if (pixels_to_clear.empty())
		{
			break;
		}

		for (const Vector2i &point : pixels_to_clear)
		{
			image->set_pixel(
				point.x,
				point.y,
				Color(0.0, 0.0, 0.0, 0.0)
			);
		}
	}
}

void MenuOptimizer::keep_largest_opaque_component(Ref<Image> image)
{
	if (image.is_null() || image->is_empty())
	{
		return;
	}

	const int width = image->get_width();
	const int height = image->get_height();

	if (width <= 0 || height <= 0)
	{
		return;
	}

	const int total_pixels = width * height;

	std::vector<uint8_t> visited(
		static_cast<size_t>(total_pixels),
		0
	);

	std::vector<Vector2i> largest_component;

	const Vector2i offsets[8] = {
		Vector2i(-1, -1),
		Vector2i(0, -1),
		Vector2i(1, -1),
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(-1, 1),
		Vector2i(0, 1),
		Vector2i(1, 1)
	};

	for (int y = 0; y < height; ++y)
	{
		for (int x = 0; x < width; ++x)
		{
			const int start_index = y * width + x;

			if (visited[static_cast<size_t>(start_index)] != 0)
			{
				continue;
			}

			visited[static_cast<size_t>(start_index)] = 1;

			if (image->get_pixel(x, y).a <= 0.03)
			{
				continue;
			}

			std::vector<Vector2i> component;
			component.emplace_back(x, y);

			size_t queue_index = 0;

			while (queue_index < component.size())
			{
				const Vector2i point = component[queue_index++];

				for (const Vector2i &offset : offsets)
				{
					const int nx = point.x + offset.x;
					const int ny = point.y + offset.y;

					if (
						nx < 0
						|| ny < 0
						|| nx >= width
						|| ny >= height
					)
					{
						continue;
					}

					const int pixel_index = ny * width + nx;

					if (
						visited[
							static_cast<size_t>(pixel_index)
						] != 0
					)
					{
						continue;
					}

					visited[
						static_cast<size_t>(pixel_index)
					] = 1;

					if (image->get_pixel(nx, ny).a > 0.03)
					{
						component.emplace_back(nx, ny);
					}
				}
			}

			if (component.size() > largest_component.size())
			{
				largest_component = std::move(component);
			}
		}
	}

	if (largest_component.empty())
	{
		return;
	}

	std::vector<uint8_t> keep(
		static_cast<size_t>(total_pixels),
		0
	);

	for (const Vector2i &point : largest_component)
	{
		const int index = point.y * width + point.x;
		keep[static_cast<size_t>(index)] = 1;
	}

	for (int y = 0; y < height; ++y)
	{
		for (int x = 0; x < width; ++x)
		{
			const int index = y * width + x;

			if (keep[static_cast<size_t>(index)] != 0)
			{
				continue;
			}

			if (image->get_pixel(x, y).a > 0.0)
			{
				image->set_pixel(
					x,
					y,
					Color(0.0, 0.0, 0.0, 0.0)
				);
			}
		}
	}
}
