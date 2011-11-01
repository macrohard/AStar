package com.sothink.heroonline.utils.astar
{
	import flash.geom.Point;
	
	import org.spicefactory.lib.logging.LogContext;
	import org.spicefactory.lib.logging.Logger;


	public class Astar
	{

		private static const _straightCost:int = 1000;

		private static const _diagCost:int = 1414;

		private static const _halfStraightCost:int = 500;

		private static const _halfDiagCost:int = 707;

		private static const _delay:int = 0;


		private static var _grid:Grid;

		private static var _endNode:Node;

		private static var _startNode:Node;

		private static var _bootTimer:uint;



		private static const logger:Logger = LogContext.getLogger("utils.astar");

		/**
		 * 根据可通过性数组，创建网格
		 * @param walkables
		 * @param rows
		 * @param columns
		 * @return
		 *
		 */
		public static function initGrid(walkables:Vector.<Boolean>, rows:int, columns:int):Grid
		{
			_grid = new Grid(walkables, rows, columns);
			return _grid;
		}

		/**
		 * 设置网格。在有多个地图同时运行时，可考虑保存多份网格，随时切换
		 * @param value
		 *
		 */
		public static function set grid(value:Grid):void
		{
			_grid = value;
		}

		/**
		 * 对本方多个角色同时寻径。根据h值决定寻径先后顺序，同样根据h值，确定目的地周边格子为目标地点。
		 * 同时寻径的优势在于避免本方人员之间的碰撞（由于碰撞检测在服务器端，如果不在寻径时处理，会造成频繁的拉扯，甚至角色移动中的穿越现象）
		 * @param targets 移动目标数组
		 * @param endNode 目标点
		 * @param ignoreEnemyPath 是否忽略敌方路径
		 *
		 */
		public static function multiFindPath(targets:Vector.<ITarget>, endNode:Node,
											 ignoreEnemyPath:Boolean = false):void
		{
			logger.debug("=====================MultiFindPath=========================");

			_endNode = endNode;
			var temp:Vector.<TimeSection> = new Vector.<TimeSection>();

			var tt:ITarget, n:Node, i:int, c:int = targets.length;
			for (i = 0; i < c; i++)
			{
				tt = targets[i];
				n = tt.startNode;
				n.h = diagonal(n.x, _endNode.x, n.y, _endNode.y) * tt.speed;
				var time:int = tt.startTimestamp + _delay;
				temp.push(n.addTimeSection(time, time, time + _halfDiagCost * tt.speed * 0.001));
			}
			targets.sort(compareH);

			var alreadyAsTarget:Vector.<Node> = new Vector.<Node>();
			for (i = 0; i < c; i++)
			{
				tt = targets[i];

				_startNode = tt.startNode;
				_startNode.g = 0;
				_startNode.h = diagonal(_startNode.x, _endNode.x, _startNode.y, _endNode.y);
				_startNode.f = _startNode.g + _startNode.h;
				_startNode.enterTime = tt.startTimestamp + _delay;
				_startNode.centTime = _startNode.enterTime;
				_bootTimer = _startNode.enterTime;

				//寻完一个移除一个临时时间片
				for each (var t:TimeSection in temp)
					if (t.node == _startNode)
					{
						t.remove();
						temp.splice(temp.indexOf(t), 1);
						break;
					}

				var endNode:Node = getTargetNode(getRangeNodes(tt.skillRange, ignoreEnemyPath, alreadyAsTarget));
				var path:Vector.<TimeSection> = search(tt, endNode, ignoreEnemyPath);
				tt.path = path;

				//将目标点加入标记为终点
				alreadyAsTarget.push(path[path.length - 1].node);
				logger.debug("---------------");
			}

			for each (t in temp)
				t.remove();
		}


		/**
		 * 单个对象寻径
		 * @param target 移动目标
		 * @param endNode 目标点
		 * @param ignoreEnemyPath 是否忽略敌方的路径
		 *
		 */
		public static function findPath(target:ITarget, endNode:Node, ignoreEnemyPath:Boolean = false):void
		{
			logger.debug("---------------------SingleFindPath------------------");
			_bootTimer = target.startTimestamp + _delay;
			_startNode = target.startNode;
			_endNode = endNode;

			_startNode.g = 0;
			_startNode.h = diagonal(_startNode.x, _endNode.x, _startNode.y, _endNode.y);
			_startNode.f = _startNode.g + _startNode.h;
			_startNode.enterTime = _bootTimer;
			_startNode.centTime = _bootTimer;

			target.path = search(target, getTargetNode(getRangeNodes(target.skillRange, ignoreEnemyPath)),
								 ignoreEnemyPath);
		}


		/**
		 * 在地点范围中搜索与起始点h值最低的地点作为目的地
		 * @param nodes
		 * @return
		 *
		 */
		private static function getTargetNode(nodes:Vector.<Node>):Node
		{
			if (nodes.length == 1)
				return nodes[0];

			var lowest:Number;
			var node:Node;
			var c:int, i:int, t:int, n:Node;

			//对同一圈内可作为目标格子的范围再次根据距离排序，同属于最近距离的格子优先使用
			node = nodes[0];
			lowest = diagonal(node.x, _endNode.x, node.y, _endNode.y);

			c = nodes.length;
			var temp:Vector.<Node> = new Vector.<Node>();
			temp.push(node);
			for (i = 1; i < c; i++)
			{
				n = nodes[i];
				t = diagonal(n.x, _endNode.x, n.y, _endNode.y);
				if (t < lowest)
				{
					lowest = t;
					temp = new Vector.<Node>();
					temp.push(n);
				}
				else if (t == lowest)
				{
					temp.push(n);
				}
			}
			nodes = temp;
			if (nodes.length == 1)
				return nodes[0];

			//对过滤后可作为目标格子的范围根据谁离起点近排序
			node = nodes[0];
			lowest = diagonal(_startNode.x, node.x, _startNode.y, node.y);
			c = nodes.length;
			for (i = 1; i < c; i++)
			{
				n = nodes[i];
				t = diagonal(_startNode.x, n.x, _startNode.y, n.y);
				if (t < lowest)
				{
					lowest = t;
					node = n;
				}
			}
			return node;
		}


		/**
		 * 获取与目标地点最近的地点范围
		 * @param node
		 * @return
		 *
		 */
		private static function getRangeNodes(range:Number, ignoreEnemyPath:Boolean,
											  alreadyAsTarget:Vector.<Node> = null):Vector.<Node>
		{
			var test:Node;
			var ns:Vector.<Node> = new Vector.<Node>();
			var i:int, j:int, c:int, d:int;
			var startX:int, startY:int, endX:int, endY:int;

			//按攻击范围选目的地
			if (range > 0)
			{
				range *= 1000;

				var begin:Boolean = false;
				while (true)
				{
					startX = Math.max(0, _endNode.x - c);
					endX = Math.min(_grid.columns - 1, _endNode.x + c);
					startY = Math.max(0, _endNode.y - c);
					endY = Math.min(_grid.rows - 1, _endNode.y + c);

					var temp:Vector.<Node> = new Vector.<Node>();
					for (i = startX; i <= endX; i++)
						for (j = startY; j <= endY; j++)
							if (Math.abs(i - _endNode.x) == c || Math.abs(j - _endNode.y) == c)
							{
								test = _grid.getNode(i, j);
								d = diagonal(test.x, _endNode.x, test.y, _endNode.y);
								if (d <= range)
									temp.push(test);
							}

					if (temp.length > 0)
					{
						begin = true;
						for (i = 0; i < temp.length; i++)
						{
							test = temp[i];
							//如果是寻路时不是障碍物，且没有被其它同时寻径的角色作为目标格子，则加入到可选格子中。
							if (test.getWalkable(uint.MAX_VALUE, _bootTimer, ignoreEnemyPath) &&
									(!alreadyAsTarget || alreadyAsTarget.indexOf(test) == -1))
								ns.push(test);

						}
					}
					else
					{
						if (begin)
							break;
					}

					c++;
				}

				if (ns.length > 0)
					return ns;
			}

			//按离目标最近选目的地
			c = 0;
			while (ns.length == 0)
			{
				startX = Math.max(0, _endNode.x - c);
				endX = Math.min(_grid.columns - 1, _endNode.x + c);
				startY = Math.max(0, _endNode.y - c);
				endY = Math.min(_grid.rows - 1, _endNode.y + c);

				for (i = startX; i <= endX; i++)
					for (j = startY; j <= endY; j++)
						if (Math.abs(i - _endNode.x) == c || Math.abs(j - _endNode.y) == c)
						{
							test = _grid.getNode(i, j);
							//如果是寻路时不是障碍物，且没有被其它同时寻径的角色作为目标格子，则加入到可选格子中。
							if (test.getWalkable(uint.MAX_VALUE, _bootTimer, ignoreEnemyPath) &&
									(!alreadyAsTarget || alreadyAsTarget.indexOf(test) == -1))
								ns.push(test);

						}

				c++;
			}

			return ns;
		}






		/**
		 * 寻路。根据可通过性及时间片来确定障碍
		 * @param speed
		 * @return
		 *
		 */
		private static function search(target:ITarget, endNode:Node, ignoreEnemyPath:Boolean):Vector.<TimeSection>
		{
			logger.debug("startNode:(" + _startNode.x + ":" + _startNode.y + ")" + " [" + _startNode.enterTime + ":" + _startNode.centTime + "]");
			logger.debug("endNode:(" + endNode.x + ":" + endNode.y + ")");

			var c:int;

			var speed:Number = target.speed * 0.001;
			var open:BinaryHeap = new BinaryHeap();
			var test:Node;
			var g:int, f:int, h:int;
			var enter:uint, cent:uint, exit:uint;
			var startX:int, endX:int, startY:int, endY:int;

			_grid.init();

			var node:Node = _startNode;
			while (node != endNode)
			{
				startX = Math.max(0, node.x - 1);
				endX = Math.min(_grid.columns - 1, node.x + 1);
				startY = Math.max(0, node.y - 1);
				endY = Math.min(_grid.rows - 1, node.y + 1);

				for (var i:int = startX; i <= endX; i++)
				{
					for (var j:int = startY; j <= endY; j++)
					{
						test = _grid.getNode(i, j);
						if (test == node || test == _startNode)
							continue;

						if (node.x == i || node.y == j)
						{
							g = node.g + _straightCost;
							enter = _bootTimer + (g - _halfStraightCost) * speed;
							cent = _bootTimer + g * speed;
							if (test == endNode)
								exit = uint.MAX_VALUE;
							else
								exit = cent + _halfDiagCost * speed;

							if (!test.getWalkable(enter, exit, ignoreEnemyPath))
								continue;
						}
						else
						{
							g = node.g + _diagCost;
							enter = _bootTimer + (g - _halfDiagCost) * speed;
							cent = _bootTimer + g * speed;
							if (test == endNode)
								exit = uint.MAX_VALUE;
							else
								exit = cent + _halfDiagCost * speed;

							if (!test.getWalkable(enter, exit, ignoreEnemyPath) ||
									!_grid.getNode(node.x, test.y).getWalkable(node.centTime, cent, ignoreEnemyPath) ||
									!_grid.getNode(test.x, node.y).getWalkable(node.centTime, cent, ignoreEnemyPath))
//								(!_grid.getNode(node.x, test.y).getWalkable(node.centTime, cent) &&
//								!_grid.getNode(test.x, node.y).getWalkable(node.centTime, cent)))
							{
								continue;
							}
						}

						h = diagonal(test.x, endNode.x, test.y, endNode.y);
						f = g + h;

						if (test.isCheck == 1)
						{
							if (test.f > f)
							{
								test.f = f;
								test.g = g;
								test.h = h;
								test.enterTime = enter;
								test.centTime = cent;
								test.parent = node;
								open.arrange(test);
							}
						}
						else if (test.isCheck == 2)
						{
							if (test.f > f)
							{
								test.f = f;
								test.g = g;
								test.h = h;
								test.enterTime = enter;
								test.centTime = cent;
								test.parent = node;
							}
						}
						else
						{
							test.f = f;
							test.g = g;
							test.h = h;
							test.enterTime = enter;
							test.centTime = cent;
							test.parent = node;
							test.isCheck = 1;
							open.push(test);
							c++;
						}
					}
				}

				node.isCheck = 2;
				if (open.length == 0 || c > 50)
				{
					logger.warn("NotFound(" + _startNode.x + ":" + _startNode.y + ")" + " (" + endNode.x + ":" + endNode.y + ")");
					target.validPath = false;
					return getClosedPath();
				}

				node = open.shift();
			}

			if (!node.getWalkable(node.enterTime, uint.MAX_VALUE, true))
			{
				logger.warn("Invalid(" + _startNode.x + ":" + _startNode.y + ")" + " (" + endNode.x + ":" + endNode.y + ")");
				target.validPath = false;
				return getClosedPath();
			}

			target.validPath = true;
			return buildPath(node);
		}


		/**
		 * 找到最接近目的地的点并构建路径
		 * @param nodes
		 * @return
		 *
		 */
		private static function getClosedPath():Vector.<TimeSection>
		{
			var nodes:Vector.<Node> = _grid.getCheckNodes();
			var node:Node;

			for each (node in nodes)
				node.h = diagonal(node.x, _endNode.x, node.y, _endNode.y);

			nodes.sort(compareH2);
			for each (node in nodes)
			{
				if (node.getWalkable(node.enterTime, uint.MAX_VALUE, true))
					return buildPath(node);
			}

			return new <TimeSection>[_startNode.addTimeSection(_startNode.enterTime, _startNode.centTime,
															   uint.MAX_VALUE)];
		}

		/**
		 * 构建路径
		 * @param node
		 * @return
		 *
		 */
		private static function buildPath(node:Node):Vector.<TimeSection>
		{
			var p:Vector.<TimeSection> = new Vector.<TimeSection>();
			p.push(node.addTimeSection(node.enterTime, node.centTime, uint.MAX_VALUE));
			var subNode:Node;
			while (node != _startNode)
			{
				subNode = node;
				node = node.parent;
				p.unshift(node.addTimeSection(node.enterTime, node.centTime, subNode.enterTime));
			}

			for each (var t:TimeSection in p)
			{
				logger.debug("(" + t.node.x + ":" + t.node.y + ")" + " [" + t.begin + ":" + t.cent + ":" + t.end + "]");
			}
			return p;
		}

		/**
		 * 测量距离
		 * @param x1 横坐标1
		 * @param x2 横坐标2
		 * @param y1 纵坐标1
		 * @param y2 纵坐标2
		 * @return
		 *
		 */
		public static function diagonal(x1:int, x2:int, y1:int, y2:int):int
		{
			var dx:int = x1 - x2;
			var dy:int = y1 - y2;
			dx = dx < 0 ? -dx : dx;
			dy = dy < 0 ? -dy : dy;

			var diag:int = dx < dy ? dx : dy;
			var straight:int = dx + dy;
			return _diagCost * diag + _straightCost * (straight - 2 * diag);
		}

		/**
		 * 比较排序
		 * @param a
		 * @param b
		 * @return
		 *
		 */
		private static function compareH(a:ITarget, b:ITarget):int
		{
			if (a.startNode.h < b.startNode.h)
				return -1;
			else if (a.startNode.h > b.startNode.h)
				return 1;
			return 0;
		}


		private static function compareH2(a:Node, b:Node):int
		{
			if (a.h < b.h)
				return -1;
			else if (a.h > b.h)
				return 1;

			if (a.g < b.g)
				return -1;
			else if (a.g > b.g)
				return 1;

			return 0;
		}



		/**
		 * 将从服务器端发过来的路径关键点数组转换成时间片数组，主要用于NPC
		 * @param bootTimer 起始时间
		 * @param waypoints 路点数组
		 * @param speed 速度。毫秒/格子
		 * @param isSameGroup 是否为同一方势力角色
		 * @return
		 *
		 */
		public static function getPath(bootTimer:uint, waypoints:Vector.<Point>, speed:int,
									   isSameGroup:Boolean):Vector.<TimeSection>
		{
			waypoints = supplementPath(waypoints);

			var path:Vector.<TimeSection> = new Vector.<TimeSection>();
			var p:Point, n:Node, g:int;
			var len:int = waypoints.length;
			var enter:uint = bootTimer, center:uint, exit:uint;
			for (var i:int = 0; i < len; i++)
			{
				p = waypoints[i];
				n = _grid.getNode(p.x, p.y);
				center = bootTimer + g * speed * 0.001;

				if (i + 1 < len)
				{
					p = waypoints[i + 1];
					if (n.x == p.x || n.y == p.y)
					{
						g += _straightCost;
						exit = bootTimer + (g - _halfStraightCost) * speed * 0.001;
					}
					else
					{
						g += _diagCost;
						exit = bootTimer + (g - _halfDiagCost) * speed * 0.001;
					}
				}
				else
				{
					exit = uint.MAX_VALUE;
				}

				path.push(n.addTimeSection(enter, center, exit, isSameGroup));
				enter = exit;
			}

			for each (var t:TimeSection in path)
			{
				logger.debug("(" + t.node.x + ":" + t.node.y + ")" + " [" + t.begin + ":" + t.cent + ":" + t.end + "]");
			}
			return path;
		}

		/**
		 * 由路径关键点，获得完整路径
		 * @param path
		 * @return path
		 *
		 */
		private static function supplementPath(path:Vector.<Point>):Vector.<Point>
		{
			var npath:Vector.<Point> = new Vector.<Point>();
			if (path.length <= 1)
			{
				return path;
			}

			var index:int = 0;
			var bp:Point = path[0];
			npath.push(bp);
			while (index++ < path.length - 1)
			{
				var cp:Point = path[index];
				while (!bp.equals(cp))
				{
					var x:int = bp.x;
					var y:int = bp.y;
					if (cp.x > bp.x)
						x++;
					else if (cp.x < bp.x)
						x--;

					if (cp.y > bp.y)
						y++;
					else if (cp.y < bp.y)
						y--;

					bp = new Point(x, y);
					npath.push(bp);
				}
			}
			return npath;
		}

	}
}
