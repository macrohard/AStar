package com.sothink.heroonline.utils.astar
{


    public interface ITarget
    {
		/**
		 * 起点格子
		 */
        function get startNode():Node;

		/**
		 * 起始时间。即到达新路径起点格子中心时的时间值
		 */
        function get startTimestamp():uint;
		
		/**
		 * 目标的速度。速度单位，毫秒/格子
		 */
		function get speed():int;
		
		/**
		 * 寻径结果
		 */
		function set path(value:Vector.<TimeSection>):void;
		
		/**
		 * 寻径结果是否正确
		 */
		function set validPath(value:Boolean):void;
		
		/**
		 * 攻击范围。如果非攻击模式，此值应该为0
		 */
		function get skillRange():Number;
    }
}