package
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.XMLSocket;
	
	
	public class TSUtil
	{
		public static const FATAL:int = 1000;
		
		public static const ERROR:int = 8;
		
		public static const WARN:int = 6;
		
		public static const INFO:int = 4;
		
		public static const DEBUG:int = 2;
		
		public static const ALL:int = 0;
		
		
		private static var useSocket:Boolean = true;
		
		private static var socket:XMLSocket;
		
		private static var prefix:String = "!SOS";
		
		private static var cache:Vector.<String> = new Vector.<String>();
		
		private static var logLevel:int = ALL;
		
		
		
		public static function setLogLevel(level:int):void
		{
			logLevel = level;
		}
		
		private static function connect():Boolean
		{
			if (!socket)
			{
				socket = new XMLSocket();
				socket.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
				socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
				socket.addEventListener(Event.CONNECT, onConnect);
				socket.addEventListener(Event.CLOSE, onClose);
				socket.connect("localhost", 4444);
			}
			
			return socket.connected;
		}
		
		private static function onIOError(e:IOErrorEvent):void
		{
			socket.close();
			useSocket = false;
			send("XMLSocket IOError", "ERROR");
			
			for each(var log:String in cache)
			{
				trace(log);
			}
			cache = null;
		}
		
		private static function onSecurityError(e:SecurityErrorEvent):void
		{
			socket.close();
			useSocket = false;
			send("XMLSocket SecurityError", "ERROR");
			
			for each(var log:String in cache)
			{
				trace(log);
			}
			cache = null;
		}
		
		private static function onConnect(e:Event):void
		{
			for each(var log:String in cache)
			{
				socket.send(log + "\n");
			}
			cache = null;
		}
		
		private static function onClose(e:Event):void
		{
			useSocket = false;
		}
		
		
		public static function send(str:*, key:String):void
		{
			var xmlMessage:XML = <showMessage key={key}/>;
			var xmlBody:XML = new XML("<![CDATA[" + str + "]]>");
			xmlMessage.appendChild(xmlBody);
			
			var msg:String = prefix + xmlMessage.toXMLString();
			
			if (useSocket)
			{
				if (connect())
				{
					socket.send(msg + "\n");
				}
				else
				{
					cache.push(msg);
				}
			}
			else
				trace(msg);
		}
		
		
		public static function Trace(str:*):void
		{
			if (logLevel > ALL)
				return;
			
			send(str, "TRACE");            
		}
		
		public static function Debug(str:*):void
		{
			if (logLevel > DEBUG)
				return;
			
			send(str, "DEBUG");
		}
		
		public static function Info(str:*):void
		{
			if (logLevel > INFO)
				return;
			
			send(str, "INFO");
		}
		
		public static function Warn(str:*):void
		{
			if (logLevel > WARN)
				return;
			
			send(str, "WARN");
		}
		
		public static function Error(str:*):void
		{
			if (logLevel > ERROR)
				return;
			
			send(str, "ERROR");
		}
		
		public static function Fatal(str:*):void
		{
			if (logLevel > FATAL)
				return;
			
			send(str, "FATAL");
		}
	}
}