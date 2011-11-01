package com.sothink.heroonline.utils.astar
{
	import flash.events.Event;
	import flash.geom.Point;


	public class TimeSection
	{
		/**
		 *进入格子的点
		 */
		public var bp:Point;

		/**
		 *在格子中的转向点,也就是中点
		 */
		public var mp:Point;

		/**
		 *走出格子的点
		 */
		public var ep:Point;


		/**
		 * 进入格子的时间
		 */
		public var begin:uint;

		/**
		 * 在格子中点的时间
		 */
		public var cent:uint;

		/**
		 * 走出格子的时间
		 */
		public var end:uint;



		private var _node:Node;

		public function get node():Node
		{
			return _node;
		}

		private var _isSameGroup:Boolean;
		



		public function TimeSection(begin:uint, cent:uint, end:uint, node:Node, isSameGroup:Boolean)
		{
			this.begin = begin;
			this.cent = cent;
			this.end = end;
			
			_node = node;
			_isSameGroup = isSameGroup;
		}

		/**
		 * 与此时间片相比较是否有相交
		 * @param enter 进入时间
		 * @param exit 离开时间
		 * @param ignoreNPCPath 是否忽略敌方路径
		 * @param strict 严格匹配。为了寻路尽快结束，搜索时采取松匹配方式，一旦发现终点，就不再确定是否能进入，
		 * 从而提前结束搜索。待搜索完成后，再一次通过严格匹配模式确定终点是否能进入
		 * @return 与此时间片相交则返回true
		 * 
		 */
		public function intersect(enter:uint, exit:uint, ignoreEnemyPath:Boolean, strict:Boolean):Boolean
		{
			if (ignoreEnemyPath && !_isSameGroup)
				return false;
			
			if (enter == uint.MAX_VALUE)
			{
				//检测当前寻径时已存在的障碍
				if (end == uint.MAX_VALUE && exit >= begin)
					return true;
			}
			else
			{
				if (exit == uint.MAX_VALUE)
				{
					//本方终点

					if (strict)
					{
						if (end == uint.MAX_VALUE)
						{
							//对方终点
							if (enter >= begin)
								return true;
						}
						else
						{
							//对方经过点
							if (enter >= begin && enter <= end)
								return true;
						}
					}
				}
				else
				{
					//本方经过点

					if (end == uint.MAX_VALUE)
					{
						//对方终点
						if (exit >= begin)
							return true;
					}
					else
					{
						//对方经过点
						if ((enter >= begin && enter <= end) || (exit >= begin && exit <= end)
							|| (enter <= begin && exit >= end))
							return true;
					}

				}
			}
			return false;
		}

		public function remove():void
		{
			_node.removeTimeSection(this);
		}
		
		public function add():void
		{
			_node.reAddTimeSection(this);
		}
	}
}