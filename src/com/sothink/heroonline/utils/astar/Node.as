package com.sothink.heroonline.utils.astar
{
	import flash.events.Event;
	
	import org.spicefactory.lib.logging.LogContext;
	import org.spicefactory.lib.logging.Logger;

	public class Node
	{
		private static const logger:Logger = LogContext.getLogger("utils.astar");
		
		
		public var f:int;
		public var g:int;
		public var h:int;
		public var parent:Node;
		public var enterTime:uint;
		public var centTime:uint;
		
		/**
		 * 未检查为0，归入开放数组为1，归入闭合数组为2
		 */
		public var isCheck:uint;
		
		
		private var _x:int;
		
		public function get x():int
		{
			return _x;
		}
		
		private var _y:int;
		
		public function get y():int
		{
			return _y;
		}

		private var _walkable:Boolean = true;

		public function get isObstacle():Boolean
		{
			return !_walkable;
		}
		
		public function set isObstacle(value:Boolean):void
		{
			_walkable = !value;
		}
		
		private var _occupy:Vector.<TimeSection>;
		
		
		public function Node(x:int, y:int, w:Boolean)
		{
			this._x = x;
			this._y = y;
			this._walkable = w;
			this._occupy = new Vector.<TimeSection>();
		}
		
		public function getWalkable(enter:uint, exit:uint, ignoreEnemyPath:Boolean, strict:Boolean = false):Boolean
		{
			if (_walkable)
			{
				for each(var t:TimeSection in _occupy)
				{
					if (t.intersect(enter, exit, ignoreEnemyPath, strict))
						return false;
				}
			}
			return _walkable;
		}
		
		/**
		 * 添加时间片
		 * @param begin 进入时间
		 * @param cent 中点时间
		 * @param end 离开时间
		 * @param isSameGroup 是否为同一方势力角色
		 * @return 
		 * 
		 */
		public function addTimeSection(begin:uint, cent:uint, end:uint, isSameGroup:Boolean = true):TimeSection
		{
//			logger.debug("add: (" + this._x + ":" + this._y + ") [" + begin + ":" + end + "]");
			var ts:TimeSection = new TimeSection(begin, cent, end, this, isSameGroup);
			_occupy.push(ts);
			return ts;
		}
		
		internal function reAddTimeSection(ts:TimeSection):void
		{
			if (_occupy.indexOf(ts) == -1)
				_occupy.push(ts);
		}
		
		internal function removeTimeSection(ts:TimeSection):void
		{
			logger.debug("remove: (" + this._x + ":" + this._y + ") [" + ts.begin + ":" + ts.end + "]");
			var p:int = _occupy.indexOf(ts);
			if (p != -1)
			{
				logger.debug("remove success");
				_occupy.splice(p, 1);
			}
		}
		
		public function get occupy():Vector.<TimeSection>
		{
			return _occupy;
		}
	}
}