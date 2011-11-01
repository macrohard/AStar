package
{
	import com.sothink.heroonline.utils.astar.ITarget;
	import com.sothink.heroonline.utils.astar.Node;
	import com.sothink.heroonline.utils.astar.TimeSection;

	public class Role implements ITarget
	{
		public var color:int;
		
		/**
		 * 目标的速度。速度单位，毫秒/格子
		 */
		private var _speed:uint = (950 - 650) * Math.random() + 650;
		
		public function get speed():uint
		{
			return _speed;
		}
		
		
		
		/**
		 * 目标起始格子
		 */
		private var _node:Node;
		
		public function get node():Node
		{
			return _node;
		}
		
		public function set node(value:Node):void
		{
			_node = value;
		}
		
		
		
		/**
		 * 起始时间。即到达新路径起点格子中心时的时间值
		 */
		private var _boottimer:int;
		
		public function get bootTimer():int
		{
			return _boottimer;
		}
		
		public function set bootTimer(value:int):void
		{
			_boottimer = value;
		}
		
		
		/**
		 * 寻径结果
		 */
		private var _path:Vector.<TimeSection>;
		
		public function get path():Vector.<TimeSection>
		{
			return _path;
		}
		
		public function set path(value:Vector.<TimeSection>):void
		{
			_path = value;
		}
		
		
		
		
		
		public function Role()
		{
			var r:int = 200 * Math.random();
			var g:int = 200 * Math.random();
			var b:int = 200 * Math.random();
			color = r << 16 | g << 8 | b;
		}
	}
}