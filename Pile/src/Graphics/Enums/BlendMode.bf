using System;

namespace Pile
{
	public enum BlendOperations : uint8
	{
	    Add,
	    Subtract,
	    ReverseSubtract,
	    Min,
	    Max
	}

	public enum BlendFactors : uint8
	{
	    Zero,
	    One,
	    SrcColor,
	    OneMinusSrcColor,
	    DstColor,
	    OneMinusDstColor,
	    SrcAlpha,
	    OneMinusSrcAlpha,
	    DstAlpha,
	    OneMinusDstAlpha,
	    ConstantColor,
	    OneMinusConstantColor,
	    ConstantAlpha,
	    OneMinusConstantAlpha,
	    SrcAlphaSaturate,
	    Src1Color,
	    OneMinusSrc1Color,
	    Src1Alpha,
	    OneMinusSrc1Alpha
	}

	public enum BlendMask : uint8
	{
	    None    = 0,
	    Red     = 1,
	    Green   = 2,
	    Blue    = 4,
	    Alpha   = 8,
	    RGB     = Red | Green | Blue,
	    RGBA    = Red | Green | Blue | Alpha
	}

	public struct BlendMode : IEquatable<BlendMode>
	{
	    public BlendOperations colorOperation;
	    public BlendFactors colorSource;
	    public BlendFactors colorDestination;
	    public BlendOperations alphaOperation;
	    public BlendFactors alphaSource;
	    public BlendFactors alphaDestination;
	    public BlendMask mask;
	    public Color color;

	    public this(BlendOperations operation, BlendFactors source, BlendFactors destination)
	    {
	        colorOperation = alphaOperation = operation;
	        colorSource = alphaSource = source;
	        colorDestination = alphaDestination = destination;
	        mask = BlendMask.RGBA;
	        color = Color.White;
	    }

	    public this(
	        BlendOperations colorOperation, BlendFactors colorSource, BlendFactors colorDestination, 
	        BlendOperations alphaOperation, BlendFactors alphaSource, BlendFactors alphaDestination, 
	        BlendMask mask, Color color)
	    {
	        this.colorOperation = colorOperation;
	        this.colorSource = colorSource;
	        this.colorDestination = colorDestination;
	        this.alphaOperation = alphaOperation;
	        this.alphaSource = alphaSource;
	        this.alphaDestination = alphaDestination;
	        this.mask = mask;
	        this.color = color;
	    }

	    public static readonly BlendMode Normal = BlendMode(BlendOperations.Add, BlendFactors.One, BlendFactors.OneMinusSrcAlpha);
	    public static readonly BlendMode Add = BlendMode(BlendOperations.Add, BlendFactors.One, BlendFactors.DstAlpha);
	    public static readonly BlendMode Subtract = BlendMode(BlendOperations.ReverseSubtract, BlendFactors.One, BlendFactors.One);
	    public static readonly BlendMode Multiply = BlendMode(BlendOperations.Add, BlendFactors.DstColor, BlendFactors.OneMinusSrcAlpha);
	    public static readonly BlendMode Screen = BlendMode(BlendOperations.Add, BlendFactors.One, BlendFactors.OneMinusSrcColor);

	    public static bool operator ==(BlendMode a, BlendMode b)
	    {
	        return
	            a.colorOperation == b.colorOperation &&
	            a.colorSource == b.colorSource &&
	            a.colorDestination == b.colorDestination &&
	            a.alphaOperation == b.alphaOperation &&
	            a.alphaSource == b.alphaSource &&
	            a.alphaDestination == b.alphaDestination &&
	            a.mask == b.mask &&
	            a.color == b.color;
	    }

	    public bool Equals(BlendMode mode)
	    {
	        return mode == this;
	    }
	}
}