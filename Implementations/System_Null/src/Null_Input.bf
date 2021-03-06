using System;

namespace Pile
{
	extension Input
	{
		[SkipCall]
		protected internal static override void Initialize() {}

		[SkipCall]
		protected internal static override void Destroy() {}

		[SkipCall]
		public override static void SetControllerRumbleInternal(int index, float leftMotor, float rightMotor, uint duration) {}

		[SkipCall]
		public override static void SetMouseCursor(Cursors cursor) {}

		[SkipCall]
		public override static void SetClipboardString(System.String value) {}

		[SkipCall]
		public override static void GetClipboardString(System.String buffer) {}

		public override static Point2 MousePosition
		{
			get => .Zero;

			[SkipCall]
			set {}
		}
	}
}
