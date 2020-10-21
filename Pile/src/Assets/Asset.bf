using System;

namespace Pile
{
	public class Asset<T> where T : Object
	{
		readonly String name ~ delete _;
		readonly Packages packages;
		T asset;

		public T Asset => asset;

		public this(StringView assetName, Packages packages = null)
		{
			this.name = new String(assetName);
			this.packages = packages == null ? Core.Packages : packages;

			this.packages.OnLoadPackage.Add(new => PackageLoaded);
			this.packages.OnUnloadPackage.Add(new => PackageUnloaded);

			asset = this.packages.[Friend]Assets.Get<T>(name); // Will set it to reference the asset or null
		}

		public ~this()
		{
			packages.OnLoadPackage.Remove(scope => PackageLoaded, true);
			packages.OnUnloadPackage.Remove(scope => PackageUnloaded, true);
		}

		public T AssetOrDefault(T def) => asset == null ? def : asset;

		void PackageLoaded(Package package)
		{
			if (asset != null) return; // Already have asset

			if (package.OwnsAsset(typeof(T), name) || (typeof(T) == typeof(Subtexture) && package.OwnsPackerTexture(name)))
				asset = packages.[Friend]Assets.Get<T>(name); // Get it
		}

		void PackageUnloaded(Package package)
		{
			if (asset == null) return; // Don't have asset

			if (package.OwnsAsset(typeof(T), name) || (typeof(T) == typeof(Subtexture) && package.OwnsPackerTexture(name)))
				asset = null; // Leave it
		}

		public static operator T(Asset<T> assetHandler) => assetHandler.asset;
	}
}