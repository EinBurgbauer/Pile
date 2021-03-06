using System;
using System.Diagnostics;

using internal Pile;

namespace Pile
{
	abstract class Game<T> : Game where T : Game
	{
		public static T Instance;

		this
		{
			Runtime.Assert(typeof(T).IsSubtypeOf(typeof(Game)), "T should be the type of the class that inherits from Game<T>");
			Runtime.Assert(Instance == null, scope $"{typeof(T)}.Instance already set. There can only be one Game instance");

			Instance = (T)this;
		}

		public ~this()
		{
			Instance = null;
		}
	}

	abstract class Game
	{
		protected virtual void Startup() {}
		protected virtual void Shutdown() {}

		protected virtual void Update() {}
		protected virtual void Render() {}

		protected virtual void Step() {}
	}
}
