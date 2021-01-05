using System;
using System.Diagnostics;

using internal Pile;

namespace Pile
{
	public class GlobalSource : AudioSource
	{
		public extern float Pan { get; set; }

		public this(MixingBus output = null, bool prioritized = false, bool stopOnDelete = true, bool stopInaudible = false)
		{
			Debug.Assert(Core.Audio != null, "Core needs to be initialized before creating platform dependent objects");

			Prioritized = prioritized;
			StopOnDelete = stopOnDelete;
			StopInaudible = stopInaudible;

			Initialize();
			SetupOutput(output);
		}
	}
}