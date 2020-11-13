using System;
using System.Collections;

namespace Pile
{
	public class SpriteFont
	{
		public class Character
		{
			public readonly char16 Unicode;
			public readonly Subtexture Image;
			public readonly Vector2 Offset;
			public readonly float Advance;

			public readonly Dictionary<char16, float> Kerning = new Dictionary<char16, float>() ~ delete _;

			public this(char16 unicode, Subtexture image, Vector2 offset, float advance)
			{
				Unicode = unicode;
				Image = image;
				Offset = offset;
				Advance = advance;
			}
		}

		public readonly Dictionary<char16, Character> Charset = new Dictionary<char16, Character>() ~ DeleteDictionaryAndItems!(_);

		//public String FamilyName = new String() ~ delete _;
		//public String StyleName = new String() ~ delete _;

		public readonly int32 Size;
		public readonly float Ascent;
		public readonly float Descent;
		public readonly float LineSpacing; // Vertical gap between lines
		public readonly float Height; // Ascent - Descent (font height)
		public readonly float LineHeight; // Ascent + Descent (height of a line, includes line gap)

		public this(Font font, int32 size, Span<char16> charset, TextureFilter filter = .Linear)
		{

		}

		public float WidthOf(Span<char16> text)
		{
		    var width = 0f;
		    var line = 0f;

		    for (int i = 0; i < text.Length; i++)
		    {
		        if (text[i] == '\n')
		        {
		            if (line > width)
		                width = line;
		            line = 0;
		            continue;
		        }

		        if (!Charset.TryGetValue(text[i], let ch))
		            continue;

		        line += ch.Advance;
		    }

		    return Math.Max(width, line);
		}

		public float WidthOf(Span<char8> text)
		{
		    var width = 0f;
		    var line = 0f;

		    for (int i = 0; i < text.Length; i++)
		    {
		        if (text[i] == '\n')
		        {
		            if (line > width)
		                width = line;
		            line = 0;
		            continue;
		        }

		        if (!Charset.TryGetValue((char16)text[i], let ch))
		            continue;

		        line += ch.Advance;
		    }

		    return Math.Max(width, line);
		}

		public float HeightOf(Span<char16> text)
		{
		    if (text.Length <= 0)
		        return 0;

		    var height = Height;

		    for (int i = 0; i < text.Length; i++)
		    {
		        if (text[i] == '\n')
		            height += LineHeight;
		    }

		    return height;
		}

		public float HeightOf(Span<char8> text)
		{
		    if (text.Length <= 0)
		        return 0;

		    var height = Height;

		    for (int i = 0; i < text.Length; i++)
		    {
		        if (text[i] == '\n')
		            height += LineHeight;
		    }

		    return height;
		}

		public Vector2 SizeOf(Span<char16> text)
		{
		    return Vector2(WidthOf(text), HeightOf(text));
		}

		public Vector2 SizeOf(Span<char8> text)
		{
		    return Vector2(WidthOf(text), HeightOf(text));
		}
	}
}