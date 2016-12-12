package com.nodename.delaunay;

import com.nodename.geom.Point;


class HalfedgePriorityQueue // also known as heap
{
	private var _hash:Array<Halfedge>;
	private var _count:Int;
	private var _minBucket:Int;
	private var _hashsize:Int;
	
	private var _ymin:Float = 0;
	private var _deltay:Float = 0;
	
	public function new(ymin:Float, deltay:Float, sqrt_nsites:Int)
	{
		_ymin = ymin;
		_deltay = deltay;
		_hashsize = 4 * sqrt_nsites;
		initialize();
	}
	
	public function dispose():Void
	{
		// get rid of dummies
		for (i in 0..._hashsize)
		{
			_hash[i].dispose();
			_hash[i] = null;
		}
		_hash = null;
	}

	private function initialize():Void
	{
		var i:Int;
	
		_count = 0;
		_minBucket = 0;
		_hash = new Array<Halfedge>();
		_hash[_hashsize - 1] = null;
		// dummy Halfedge at the top of each hash
		for (i in 0..._hashsize)
		{
			_hash[i] = Halfedge.createDummy();
			_hash[i].nextInPriorityQueue = null;
		}
	}

	public function insert(halfEdge:Halfedge):Void
	{
		var previous:Halfedge, next:Halfedge;
		var insertionBucket:Int = bucket(halfEdge);
		if (insertionBucket < _minBucket)
		{
			_minBucket = insertionBucket;
		}
		previous = _hash[insertionBucket];
		while ((next = previous.nextInPriorityQueue) != null
		&&     (halfEdge.ystar  > next.ystar || (halfEdge.ystar == next.ystar && halfEdge.vertex.x > next.vertex.x)))
		{
			previous = next;
		}
		halfEdge.nextInPriorityQueue = previous.nextInPriorityQueue; 
		previous.nextInPriorityQueue = halfEdge;
		++_count;
	}

	public function remove(halfEdge:Halfedge):Void
	{
		var removalBucket = bucket(halfEdge);
		
		if (halfEdge.vertex != null)
		{
			var previous = _hash[removalBucket];
			while (previous.nextInPriorityQueue != halfEdge)
			{
				previous = previous.nextInPriorityQueue;
			}
			previous.nextInPriorityQueue = halfEdge.nextInPriorityQueue;
			_count--;
			halfEdge.vertex = null;
			halfEdge.nextInPriorityQueue = null;
			halfEdge.dispose();
		}
	}

	private function bucket(halfEdge:Halfedge):Int
	{
		var theBucket:Int = Std.int((halfEdge.ystar - _ymin) / _deltay * _hashsize);
		if (theBucket < 0) theBucket = 0;
		if (theBucket >= _hashsize) theBucket = _hashsize - 1;
		return theBucket;
	}
	
	private function isEmpty(bucket:Int):Bool
	{
		return (_hash[bucket].nextInPriorityQueue == null);
	}
	
	/**
	 * move _minBucket until it contains an actual Halfedge (not just the dummy at the top); 
	 * 
	 */
	private function adjustMinBucket():Void
	{
		while (_minBucket < _hashsize - 1 && isEmpty(_minBucket))
		{
			++_minBucket;
		}
	}

	public function empty():Bool
	{
		return _count == 0;
	}

	/**
	 * @return coordinates of the Halfedge's vertex in V*, the transformed Voronoi diagram
	 * 
	 */
	public function min():Point
	{
		adjustMinBucket();
		var answer:Halfedge = _hash[_minBucket].nextInPriorityQueue;
		return new Point(answer.vertex.x, answer.ystar);
	}

	/**
	 * remove and return the min Halfedge
	 * @return 
	 * 
	 */
	public function extractMin():Halfedge
	{
		// get the first real Halfedge in _minBucket
		var answer = _hash[_minBucket].nextInPriorityQueue;
		
		_hash[_minBucket].nextInPriorityQueue = answer.nextInPriorityQueue;
		_count--;
		answer.nextInPriorityQueue = null;
		
		return answer;
	}

}
