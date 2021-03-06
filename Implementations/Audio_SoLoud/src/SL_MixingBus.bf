using System.Diagnostics;
using System.Collections;
using SoLoud;

using internal Pile;

namespace Pile
{
	extension MixingBus
	{
		internal uint32 slBusHandle; // external only. Is set when this is played on SoLoud or another Bus, used again when removing
		internal Bus* slBus;

		List<MixingBus> busInputs = new List<MixingBus>() ~ delete _;
		List<AudioSource> sourceInputs = new List<AudioSource>() ~ delete _;

		public ~this()
		{
			SL_Bus.Destroy(slBus);
		}

		protected override void Initialize()
		{
			slBus = SL_Bus.Create();

			Debug.Assert(slBus != null, "Failed to create SL_MixingBus (Bus)");
		}

		protected override void SetVolume(float volume)
		{
			SL_Bus.SetVolume(slBus, volume);
		}

		protected internal override void AddBus(MixingBus mixingBus)
		{
			mixingBus.slBusHandle = SL_Bus.Play(slBus, mixingBus.slBus);

			busInputs.Add(mixingBus);
		}

		protected internal override void RemoveBus(MixingBus mixingBus)
		{
			SL_Soloud.Stop(Audio.slPtr, mixingBus.slBusHandle);

			busInputs.Remove(mixingBus);
		}

		protected internal override void AddSource(AudioSource source)
		{
			source.slBusHandle = SL_Bus.Play(slBus, source.slBus);

			sourceInputs.Add(source);
		}

		protected internal override void RemoveSource(AudioSource source)
		{
			SL_Soloud.Stop(Audio.slPtr, source.slBusHandle);

			sourceInputs.Remove(source);
		}

		protected override void RedirectInputsToMaster()
		{
			for (let mixingBus in busInputs)
			{
				// Stop voice
				SL_Soloud.Stop(Audio.slPtr, mixingBus.slBusHandle);

				// Replay
				mixingBus.output = Audio.MasterBus;
				Audio.MasterBus.AddBus(mixingBus);
			}
			busInputs.Clear();

			for (let audioSource in sourceInputs)
			{
				// Stop voice
				SL_Soloud.Stop(Audio.slPtr, audioSource.slBusHandle);

				// Replay
				audioSource.output = Audio.MasterBus;
				Audio.MasterBus.AddSource(audioSource);
			}
			busInputs.Clear();
		}
	}
}
