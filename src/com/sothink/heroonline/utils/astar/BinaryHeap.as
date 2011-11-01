package com.sothink.heroonline.utils.astar
{


    public class BinaryHeap
    {
        private var _heap:Vector.<Node>;


        public function get length():uint
        {
            return _heap.length;
        }


        public function BinaryHeap()
        {
            _heap = new Vector.<Node>();
        }

        public function indexOf(node:Node):int
        {
            return _heap.indexOf(node);
        }
		
		public function concat(array:Vector.<Node>):Vector.<Node>
		{
			return _heap.concat(array);
		}

        public function push(node:Node):void
        {
            _heap.push(node);
			rise(node);
        }
		
		public function arrange(node:Node):void
		{
			rise(node);
		}

        public function shift():Node
        {
            var f:Node = _heap.shift();

            var node:Node = _heap.pop();
			if (node)
			{
            	_heap.unshift(node);
            	fall(node);
			}

            return f;
        }
		
		private function rise(node:Node):void
		{
			var index:int, parentIndex:int, n:Node;
			while (true)
			{
				index = _heap.indexOf(node);
				parentIndex = int((index + 1) >> 1) - 1;
				if (parentIndex < 0)
					break;
				
				n = _heap[parentIndex];
				if (n.f > node.f)
					swapItem(n, parentIndex, node, index);
				else
					break;
			}
		}
		
		private function fall(node:Node):void
		{
			var c:int = _heap.length;
			var index:int, subIndexA:int, subIndexB:int, subA:Node, subB:Node;
			var min:Node, minIndex:int;
			while (true)
			{
				index = _heap.indexOf(node);
				subIndexB = 2 * (index + 1);
				subIndexA = subIndexB - 1;
				
				if (subIndexB < c)
				{
					subA = _heap[subIndexA];
					subB = _heap[subIndexB];
					
					if (subA.f < subB.f)
					{
						min = subA;
						minIndex = subIndexA;
					}
					else
					{
						min = subB;
						minIndex = subIndexB;
					}
					
					if (node.f > min.f)
						swapItem(node, index, min, minIndex);
					else
						break;
				}
				else if (subIndexB == c)
				{
					subA = _heap[subIndexA];
					if (node.f > subA.f)
						swapItem(subA, subIndexA, node, index);
					
					break;
				}
				else
				{
					break;
				}
			}
		}

        

        private function swapItem(a:Node, aIndex:int, b:Node, bIndex:int):void
        {
            _heap[aIndex] = b;
            _heap[bIndex] = a;
        }
    }
}