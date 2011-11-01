package
{
	import com.sothink.heroonline.utils.astar.Astar;
	import com.sothink.heroonline.utils.astar.Diagonal;
	import com.sothink.heroonline.utils.astar.Grid;
	import com.sothink.heroonline.utils.astar.ITarget;
	import com.sothink.heroonline.utils.astar.Node;
	import com.sothink.heroonline.utils.astar.TimeSection;
	
	import fl.controls.Button;
	import fl.controls.Label;
	import fl.controls.TextArea;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.getTimer;


	[SWF(frameRate="60", width="800", height="640")]
	public class AStarDemo extends Sprite
	{
		private var canvas:BitmapData;

		private var step:uint = 16;

		private var canvaswidth:int = 640;

		private var rows:uint;

		private var columns:uint;

		private var drawObstacle:Boolean;



		private var grid:Grid;

		private var roles:Vector.<Role> = new Vector.<Role>();



		private var btnClear:Button;

		private var txaInfo:TextArea;

		private var lblMsg:Label;


		
		private var loader:URLLoader;
		

		public function AStarDemo()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;

			graphics.lineStyle(0, 0x666666, 1, true);
			var command:Vector.<int> = new Vector.<int>();
			var coord:Vector.<Number> = new Vector.<Number>();


			for (var i:int; i <= canvaswidth; i += step)
			{
				command.push(1);
				coord.push(0, i);
				command.push(2);
				coord.push(canvaswidth, i);

				command.push(1);
				coord.push(i, 0);
				command.push(2);
				coord.push(i, canvaswidth);

			}

			graphics.drawPath(command, coord);
			this.cacheAsBitmap = true;



			rows = columns = canvaswidth / step;
			var walkables:Vector.<Boolean> = new Vector.<Boolean>(rows * columns, true);
			for (var j:int; j < walkables.length; j++)
			{
				walkables[j] = true;
			}
			grid = Astar.initGrid(walkables, rows, columns);


			canvas = new BitmapData(canvaswidth, canvaswidth, true, 0);
			addChild(new Bitmap(canvas));


			stage.addEventListener(MouseEvent.MOUSE_DOWN, onmousedown);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onmousemove);
			stage.addEventListener(MouseEvent.MOUSE_UP, onmouseup);

			btnClear = new Button();
			btnClear.x = 660;
			btnClear.y = 30;
			btnClear.label = "重置";
			btnClear.addEventListener(MouseEvent.CLICK, onclear);
			addChild(btnClear);

			txaInfo = new TextArea();
			txaInfo.x = 650;
			txaInfo.y = 70;
			txaInfo.width = 140;
			txaInfo.height = 300;
			txaInfo.editable = false;
			addChild(txaInfo);

			lblMsg = new Label();
			lblMsg.x = 650;
			lblMsg.y = 375;
			lblMsg.width = 140;
			lblMsg.height = 300;
			addChild(lblMsg);
			
			
			
			loader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener(Event.COMPLETE, loadCompleteHandler);
			loader.load(new URLRequest("assets/diagonal.pbj"));
		}
		
		private function loadCompleteHandler(event:Event):void
		{
			Diagonal.init(loader.data);
		}

		private function onclear(e:MouseEvent):void
		{
			roles = new Vector.<Role>();

			var walkables:Vector.<Boolean> = new Vector.<Boolean>(rows * columns, true);
			for (var j:int; j < walkables.length; j++)
			{
				walkables[j] = true;
			}
			grid = Astar.initGrid(walkables, rows, columns);

			canvas.fillRect(canvas.rect, 0);
		}

		private function clearPath():void
		{
			var r:Role;
			for each (r in roles)
			{
				for each (var t:TimeSection in r.path)
				{
					if (!t.node.isObstacle)
						drawTile(0xFFFFFF, t.node.x, t.node.y);
					t.remove();
				}
			}

			for each (r in roles)
			{
				drawTile(r.color, r.node.x, r.node.y);
				drawFlagTile(0xFFFFFF, r.node.x, r.node.y);
			}
		}

		private function onmousedown(e:MouseEvent):void
		{
			if (e.stageX >= canvaswidth || e.stageY >= canvaswidth || e.stageX < 0 || e.stageY < 0)
				return;

			if (e.ctrlKey)
			{
				drawObstacle = true;
			}
			else
			{
				var x:int, y:int, r:Role;
				x = e.localX / step;
				y = e.localY / step;

				if (e.altKey)
				{
					var n:Node = grid.getNode(x, y);
					for each (r in roles)
					{
						if (r.node == n)
							return;
					}

					r = new Role();
					r.node = n;
					roles.push(r);
					drawTile(r.color, x, y);
					drawFlagTile(0xFFFFFF, x, y);
				}
				else
				{
					clearPath();
					var t:int = getTimer();
					if (roles.length == 1)
					{
						r = roles[0];
						lblMsg.text = "开始点:(" + r.node.x + ":" + r.node.y + ")\n";
						lblMsg.text += "速度: " + r.speed + " 毫秒/ 格子\n\n";
						lblMsg.text += "结束点:(" + x + ":" + y + ")\n\n";
						r.bootTimer = t;
						Astar.findPath(r, grid.getNode(x, y));
						if (r.path)
							drawPath(r);
						lblMsg.text += "耗时:" + (getTimer() - t);
					}
					else if (roles.length > 1)
					{
						var its:Vector.<ITarget> = new Vector.<ITarget>();
						lblMsg.text = "";
						for each (r in roles)
						{
							r.bootTimer = t;
							its.push(r);
						}

						Astar.multiFindPath(its, grid.getNode(x, y));
						for each (r in roles)
						{
							lblMsg.text += "开始点:(" + r.node.x + ":" + r.node.y + ")\n";
							lblMsg.text += "速度: " + r.speed + " 毫秒/ 格子\n\n";
							drawPath(r);
						}
						lblMsg.text += "结束点:(" + x + ":" + y + ")\n\n";
						lblMsg.text += "耗时:" + (getTimer() - t);
					}
				}
			}
		}

		private function onmousemove(e:MouseEvent):void
		{
			if (e.stageX >= canvaswidth || e.stageY >= canvaswidth || e.stageX < 0 || e.stageY < 0)
				return;

			var x:int, y:int, n:Node;
			x = e.localX / step;
			y = e.localY / step;
			if (drawObstacle)
			{
				n = grid.getNode(x, y);
				if (!n.isObstacle)
				{
					n.isObstacle = true;
					drawTile(0, x, y);
				}
			}
			else
			{
				n = grid.getNode(x, y);
				var s:String = "X: " + x + "\n" + "Y: " + y;

				for each (var r:Role in roles)
				{
					for each (var t:TimeSection in r.path)
					{
						if (t.node == n)
						{
							s += "\n\n开始点(" + r.node.x + ":" + r.node.y + ")";
							s += "\n进入: " + t.begin + "\n离开: " + t.end;
						}
					}
				}
				txaInfo.text = s;
			}
		}

		private function onmouseup(e:MouseEvent):void
		{
			drawObstacle = false;
		}

		private function drawTile(color:int, x:int, y:int, alpha:Number = 1.0):void
		{
			var t:Shape = new Shape();
			t.graphics.beginFill(color, alpha);
			t.graphics.drawRect(0, 0, step - 3, step - 3);
			t.graphics.endFill();

			var m:Matrix = new Matrix();
			m.translate(x * step + 2, y * step + 2);
			canvas.draw(t, m);
		}

		private function drawFlagTile(color:int, x:int, y:int):void
		{
			var t:Shape = new Shape();
			t.graphics.beginFill(color);
			t.graphics.drawCircle(2, 2, step * 0.2);
			t.graphics.endFill();

			var m:Matrix = new Matrix();
			m.translate(x * step + step * 0.5 - 1, y * step + step * 0.5 - 1);
			canvas.draw(t, m);
		}

		private function drawPath(r:Role):void
		{
			var n:Node;
			for (var i:int = 1; i < r.path.length; i++)
			{
				n = r.path[i].node;
				drawTile(r.color, n.x, n.y, 0.4);
			}
			n = r.path[r.path.length - 1].node;
			drawFlagTile(0, n.x, n.y);
		}
	}
}