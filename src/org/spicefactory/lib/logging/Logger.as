package org.spicefactory.lib.logging
{
	public class Logger
	{
		public function Logger()
		{
		}
		
		public function trace(str:String):void
		{
			TSUtil.Trace(str);
		}
		
		public function debug(str:String):void
		{
			TSUtil.Debug(str);
		}
		
		public function error(str:String):void
		{
			TSUtil.Error(str);
		}
	}
}