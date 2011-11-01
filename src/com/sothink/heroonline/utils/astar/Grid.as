package com.sothink.heroonline.utils.astar
{
	import org.spicefactory.lib.logging.LogContext;
	import org.spicefactory.lib.logging.Logger;


	public class Grid
	{

		private static const logger:Logger = LogContext.getLogger("utils.astar");

		private var _grids:Vector.<Node>;

		private var _rows:uint;

		public function get rows():uint
		{
			return _rows;
		}

		private var _columns:uint;

		public function get columns():uint
		{
			return _columns;
		}


		public function Grid(walkables:Vector.<Boolean>, rows:uint, columns:uint)
		{
			_rows = rows;
			_columns = columns;

			var c:uint = _rows * _columns;
			if (walkables.length != c)
				throw new Error("Incorrect walkables array!");

			_grids = new Vector.<Node>(c, true);
			for (var i:int = 0; i < c; i++)
			{
				_grids[i] = new Node(i % _columns, i / _columns, walkables[i]);
			}
		}

		public function init():void
		{
			for each (var n:Node in _grids)
				n.isCheck = 0;
		}

		public function getNode(x:uint, y:uint):Node
		{
			return _grids[y * _columns + x];
		}

		public function getCheckNodes():Vector.<Node>
		{
			var ns:Vector.<Node> = new Vector.<Node>();
			var n:Node;
			for each (n in _grids)
				if (n.isCheck != 0)
					ns.push(n);
			return ns;
		}

		public function test():void
		{
			for each (var n:Node in _grids)
			{
				if (n.occupy.length > 0)
				{
					logger.debug("Node TimeSection length:" + n.occupy.length + "[" + n.x + ":" + n.y + "]");
					for each (var t:TimeSection in n.occupy)
						logger.debug("\tbegin:" + t.begin + "\tend:" + t.end);
				}
			}
		}
	}
}