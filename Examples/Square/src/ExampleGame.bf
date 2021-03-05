using Pile;
using System;

namespace Game
{
	// TODO examples for... using audio, fonts, packages

	[AlwaysInclude]
	class ExampleGame : Game<ExampleGame>
	{
		static this()
		{
			EntryPoint.Preferences.createGame = () => new ExampleGame();
			EntryPoint.Preferences.gameTitle = "Example Game";
		}

		const float rectSpeed = 140;

		Shader batchShader ~ delete _;
		Material batchMat ~ delete _;
		Batch2D batch ~ delete _;

		// Virtual input of WASD and controller 0
		VirtualStick input = new VirtualStick()..Add(.A, .D, .W, .S)..AddLeftJoystick(0) ~ delete _;

		// Middle of the screen (origin is top left, since we're not using Camera2D or another matrix to translate)
		Vector2 rectPos = .(1280 / 2, 720 / 2);
		Rect relativeRect = Rect(-40, -40, 80, 80);

		protected override void Startup()
		{
			Log.Info("Hello!");

			// This is automatically built for us. See BeefProj.toml and Pile/Core/EntryPoint.bf @ RunPackager
			Core.Assets.LoadPackage("shaders");

			// Setup default shader for drawing with Batch2D
			let source = scope ShaderData(Core.Assets.Get<RawAsset>("s_batch2dVert").text, Core.Assets.Get<RawAsset>("s_batch2dFrag").text); 
			batchShader = new Shader(source);
			batchMat = new Material(batchShader);

			batch = new Batch2D(batchMat);

			Core.Assets.UnloadPackage("shaders"); // No need to have shader source code loaded anymore
		}

		protected override void Update()
		{
			// Move rect by input
			rectPos += input.Value.Normalize() * rectSpeed * Time.Delta;
		}

		protected override void Render()
		{
			// Clear screen and bacher buffer
			Core.Graphics.Clear(Core.Window, .Black);
			batch.Clear();

			// Raw rect at position
			batch.Rect(Rect(rectPos.Round() + relativeRect.Position, relativeRect.Size), .Red);

			// Render batch buffer
			batch.Render(Core.Window);

			//let pos = dragging ? Point2(1, 2) : Point2(0, (int)87f); // @do report bug: having this integrate in call below will error codegen
			Draw(batch, 5, dragging ? Point2(1, 2) : Point2(0, (int)87f));
		}

		bool dragging;
		void Draw(Batch2D batch, int frame, Point2 pos)
		{
			Console.Write('d');
		}
	}
}