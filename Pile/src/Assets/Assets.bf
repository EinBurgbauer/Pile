using System;
using System.IO;
using System.Collections;
using System.Diagnostics;
using JSON_Beef.Serialization;
using JSON_Beef.Types;

using internal Pile;

namespace Pile
{
	public static class Assets
	{
		static Packer packer = new Packer() { combineDuplicates = true };
		static List<Texture> atlas = new List<Texture>();
		static Dictionary<Type, Dictionary<String, Object>> assets = new Dictionary<Type, Dictionary<String, Object>>();
		static bool shutdown = false;

		public static int TextureCount => packer.SourceImageCount;
		public static int AssetCount
		{
			get
			{
				int c = 0;
				for (let typeDict in assets.Values)
					c += typeDict.Count;

				return c;
			}
		}

		static this() {}
		static ~this()
		{
			if (!shutdown)
				Shutdown();
		}

		internal static void Shutdown()
		{
			delete packer;
			DeleteContainerAndItems!(atlas);

			for (let dic in assets.Values)
				DeleteDictionaryAndKeysAndItems!(dic);

			delete assets;

			shutdown = true;
		}

		public static bool Has<T>(String name) where T : class
		{
			let type = typeof(T);

			if (!assets.ContainsKey(type))
				return false;

			if (!assets.GetValue(type).Get().ContainsKey(name))
				return false;

			return true;
		}

		public static bool Has<T>() where T : class
		{
			let type = typeof(T);

			if (!assets.ContainsKey(type))
				return false;

			return true;
		}

		public static bool Has(Type type, String name)
		{
			if (!type.IsObject || !type.HasDestructor)
				return false;

			if (!assets.ContainsKey(type))
				return false;

			if (!assets.GetValue(type).Get().ContainsKey(name))
				return false;

			return true;
		}

		public static bool Has(Type type)
		{
			if (!type.IsObject || !type.HasDestructor)
				return false;

			if (!assets.ContainsKey(type))
				return false;

			return true;
		}

		public static T Get<T>(String name) where T : class
 		{
			 if (!Has<T>(name))
				 return null;

			 return (T)assets.GetValue(typeof(T)).Get().GetValue(name).Get();
		}

		public static Object Get(Type type, String name)
		{
			if (!Has(type, name))
				return false;

			return assets.GetValue(type).Get().GetValue(name).Get();
		}

		public static AssetEnumerator<T> Get<T>() where T : class
		{
			if (!Has<T>())
				return AssetEnumerator<T>(null);

			return AssetEnumerator<T>(assets.GetValue(typeof(T)).Get());
		}

		public static Result<Dictionary<String, Object>.ValueEnumerator> Get(Type type)
		{
			if (!Has(type))
				return .Err;

			return assets.GetValue(type).Get().Values;
		}

		/** The name string passed here will be directly referenced in the dictionary, so take a fresh one, ideally the same that is also referenced in package owned assets.
		*/
		internal static Result<void> AddAsset(Type type, String name, Object object)
		{
			Debug.Assert(Core.initialized);

			if (!type.HasDestructor)
				LogErrorReturn!(scope String()..AppendF("Couldn't add asset {} of type {}, because only classes can be treated as assets", name, object.GetType()));

			if (!object.GetType().IsSubtypeOf(type))
				LogErrorReturn!(scope String()..AppendF("Couldn't add asset {} of type {}, because it is not assignable to given type {}", name, object.GetType(), type));

			if (!assets.ContainsKey(type))
				assets.Add(type, new Dictionary<String, Object>());

			else if (assets.GetValue(type).Get().ContainsKey(name))
				LogErrorReturn!(scope String()..AppendF("Couldn't add asset {} to dictionary for type {}, because the name is already taken for this type", name, type));

			assets.GetValue(type).Get().Add(name, object);

			return .Ok;
		}

		internal static void RemoveAsset(Type type, String name)
		{
			if (!assets.ContainsKey(type))
				return;
			else if (!assets.GetValue(type).Get().ContainsKey(name))
				return;

			let pair = assets.GetValue(type).Get().GetAndRemove(name).Get();

			delete pair.key;
			delete pair.value;
			
			// Delete unused dicts
			if (assets.GetValue(type).Get().Count == 0)
			{
				let dict = assets.GetAndRemove(type).Get();
				delete dict.value;
			}
		}

		internal static Result<void> AddPackerTexture(String name, Bitmap bitmap)
		{
			Debug.Assert(Core.initialized);

			// Add to packer
			packer.AddBitmap(name, bitmap);

			// Even if somebody decides to have their own asset type for subtextures like class Sprite { Subtexture subtex; }
			// It's still good to store them here, because they would need to be in some lookup for updating on packer pack anyways
			// If you want to get the subtexture (even inside the importer function), just do Assets.Get<Subtexture>(name); (this also makes it clear that you are not the one to delete it)

			// Add to assets
			let type = typeof(Subtexture);
			if (!assets.ContainsKey(type))
				assets.Add(type, new Dictionary<String, Object>());

			else if (assets.GetValue(type).Get().ContainsKey(name))
				LogErrorReturn!(scope String()..AppendF("Couldn't add asset {} to dictionary for type {}, because the name is already taken for this type", name, type));

			let tex = new Subtexture();
			assets.GetValue(type).Get().Add(name, tex); // Will be filled in on PackAndUpdate()

			return .Ok;
		}

		internal static void RemovePackerTexture(String name)
		{
			// Remove from packer
			packer.RemoveSource(name);

			// Remove from assets
			let type = typeof(Subtexture);
			if (!assets.ContainsKey(type))
				return;
			else if (!assets.GetValue(type).Get().ContainsKey(name))
				return;

			let pair = assets.GetValue(type).Get().GetAndRemove(name).Get();

			delete pair.key;
			delete pair.value;
			
			// Delete unused dicts
			if (assets.GetValue(type).Get().Count == 0)
			{
				let dict = assets.GetAndRemove(type).Get();
				delete dict.value;
			}
		}
		
		internal static void PackAndUpdate()
		{
			Debug.Assert(Core.initialized);

			// Pack sources
			let res = packer.Pack();

			if (res case .Err) return; // We can't or shouldn't pack now
			var output = res.Get();

			// Apply bitmaps to textures in atlas
			int i = 0;
			for (; i < output.Pages.Count; i++)
			{
				if (atlas.Count <= i)
					atlas.Add(new Texture(output.Pages[i]));
				else atlas[i].Set(output.Pages[i]);

				delete output.Pages[i];
			}

			// Delete unused textures from atlas
			while (i < atlas.Count)
				delete atlas.PopBack();

			// Update all Subtextures
			for (var entry in output.Entries)
			{
				// Find corresponding subtex
				let subtex = Get<Subtexture>(entry.key);

				subtex.Reset(atlas[entry.value.Page], entry.value.Source, entry.value.Frame);
				delete entry.value; // Will also delete the key, because that is the same string as the name property
			}

			output.Entries.Clear(); // We deleted these in our loops, no need to loop again
			output.Pages.Clear();

			// Get rid of output
			delete output;
		}

		// Basically copy-pasta from Dictionary.ValueEnumerator
		public struct AssetEnumerator<TAsset> : IEnumerator<TAsset>, IResettable
		{
			private Dictionary<String, Object> mDictionary;
			private int_cosize mIndex;
			private TAsset mCurrent;

			const int_cosize cDictEntry = 1;
			const int_cosize cKeyValuePair = 2;

			public this(Dictionary<String, Object> dictionary)
			{
				mDictionary = dictionary;
				mIndex = 0;
				mCurrent = default;
			}

			public bool MoveNext() mut
			{
		        // Use unsigned comparison since we set index to dictionary.count+1 when the enumeration ends.
		        // dictionary.count+1 could be negative if dictionary.count is Int32.MaxValue
				while ((uint)mIndex < (uint)mDictionary.[Friend]mCount)
				{
					if (mDictionary.mEntries[mIndex].mHashCode >= 0)
					{
						mCurrent = (TAsset)mDictionary.[Friend]mEntries[mIndex].mValue;
						mIndex++;
						return true;
					}
					mIndex++;
				}

				mIndex = mDictionary.[Friend]mCount + 1;
				mCurrent = default;
				return false;
			}

			public TAsset Current
			{
				get { return mCurrent; }
			}

			public ref String Key
			{
				get
				{
					return ref mDictionary.mEntries[mIndex].mKey;
				}
			}

			public void Dispose()
			{
			}

			public void Reset() mut
			{
				mIndex = 0;
				mCurrent = default;
			}

			public Result<TAsset> GetNext() mut
			{
				if (mDictionary == null || !MoveNext())
					return .Err;
				return Current;
			}
		}
	}
}
