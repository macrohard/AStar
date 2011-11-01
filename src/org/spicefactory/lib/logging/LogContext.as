package org.spicefactory.lib.logging
{
	public class LogContext
	{
		private static var logger:Logger;
		
		public function LogContext()
		{
		}
		
		public static function getLogger(va:String):Logger
		{
			if (!logger)
				logger = new Logger();
			return logger;
		}
	}
}