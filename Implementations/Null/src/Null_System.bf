using System;

using internal Pile;

namespace Pile
{
	public extension System : ISystemOpenGL
	{
		public override uint32 MajorVersion => 1;
		public override uint32 MinorVersion => 0;
		public override String ApiName => "Null System";
		public override String Info => String.Empty;

		protected internal override Input CreateInput()
		{
			return new Input();
		}

		protected internal override Window CreateWindow(uint32 width, uint32 height)
		{
			return new Window(width, height);
		}

		[SkipCall]
		protected internal override void Initialize() {}

		[SkipCall]
		protected internal override void Step() {}

		[SkipCall]
		public void SetGLAttributes(uint32 depthSize, uint32 stencilSize, uint32 multisamplerBuffers, uint32 multisamplerSamples) {}

		public void* GetGLProcAddress(StringView procName) => null;

		Null_Context context = new Null_Context() ~ delete _;

		public ISystemOpenGL.Context GetGLContext() => context;

		protected internal override void* GetNativeWindowHandle() => null;
	}
}
