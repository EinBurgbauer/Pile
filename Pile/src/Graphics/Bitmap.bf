using System;
using System.IO;

namespace Pile
{
	public class Bitmap
	{
		public Color[] Pixels { get; private set; }
		public int32 Width { get; private set; }
		public int32 Height { get; private set; }

		bool initialized;

		public this(int32 width, int32 height, Color[] pixels)
		{
			Runtime.Assert(width > 0 && height > 0 && width * height <= pixels.Count);

			Pixels = new Color[width * height];
			pixels.CopyTo(Pixels);

			Width = width;
			Height = height;

			initialized = true;
		}

		public this(int32 width, int32 height) : this(width, height, new Color[width * height]) {}

		public this() { } // Unitialized

		public ~this()
		{
			if (Pixels != null) delete Pixels;
		}

		public void Premultiply()
		{
			uint8* rgba = (uint8*)&(void)Pixels;

			let len = Pixels.Count * 4;
			for (int32 i = 0; i < len; i++)
			{
				rgba[i + 0] = rgba[i + 0] * rgba[i + 3] / 255;
				rgba[i + 1] = rgba[i + 1] * rgba[i + 3] / 255;
				rgba[i + 2] = rgba[i + 2] * rgba[i + 3] / 255;
			}
		}

		public void Clear()
		{
			if (!initialized) return;
			Array.Clear(&Pixels, Pixels.Count);
		}

		/**Also clears pixel data!*/
		public void Resize(int32 width, int32 height)
		{
			Width = width;
			Height = height;

			if (Pixels != null) delete Pixels;
			Pixels = new Color[width * height];

			initialized = true;
		}

		public void SetPixels(Span<Color> source)
		{
			if (!initialized) return;

			source.CopyTo(Pixels);
		}

		public void SetPixels(Rect destination, Span<Color> source)
		{
			if (!initialized) return;

			let dst = Span<Color>(Pixels);

			for (int y = 0; y < destination.Height; y++)
			{
			    let from = source.Slice(y * destination.Width, destination.Width);
			    let to = dst.Slice(destination.X + (destination.Y + y) * Width, destination.Width);

			    from.CopyTo(to);
			}
		}

		public void GetPixels(Span<Color> dest, Rect destRect, Rect sourceRect)
		{
			if (!initialized) return;

			Span<Color> src = Span<Color>(Pixels);
			var sr = sourceRect;

			// can't be outside of the source image
			if (sourceRect.Left < 0) sr.Left = 0;
			if (sourceRect.Top < 0) sr.Top = 0;
			if (sourceRect.Right > Width) sr.Right = Width;
			if (sourceRect.Bottom > Height) sr.Bottom = Height;

			// can't be larger than our destination
			if (sourceRect.Width > destRect.Width - destRect.X)
			    sr.Width = destRect.Width - destRect.X;
			if (sourceRect.Height > destRect.Height - destRect.Y)
			    sr.Height = destRect.Height - destRect.Y;

			for (int y = 0; y < sr.Height; y++)
			{
			    var from = src.Slice(sr.X + (sr.Y + y) * Width, sr.Width);
			    var to = dest.Slice(destRect.X + (destRect.Y + y) * destRect.Width, sr.Width);

			    from.CopyTo(to);
			}
		}

		public void GetSubBitmap(Rect source, Bitmap sub)
		{
			if (!initialized) return;

			sub.Resize((int32)source.Width, (int32)source.Height);
			GetPixels(sub.Pixels, Rect(0, 0, source.Width, source.Height), source);
		}

		public void CopyTo(Bitmap bitmap)
		{
			if (!initialized) return;

			bitmap.Resize(Width, Height);
			bitmap.SetPixels(Pixels);
		}
	}
}
