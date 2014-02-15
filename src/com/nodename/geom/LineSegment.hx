package com.nodename.geom;

import flash.geom.Point;

class LineSegment  {
	inline public static function squaredDist(p0 : Point, p1 : Point) {
		var dx = p0.x - p1.x;
		var dy = p0.y - p1.y;	
		return dx * dx + dy * dy;
	}
	
	public static function compareLengths_MAX(segment0:LineSegment, segment1:LineSegment):Int {
		var length0 = squaredDist(segment0.p0, segment0.p1);
		var length1 = squaredDist(segment1.p0, segment1.p1);
		if (length0 < length1) {
			return 1;
		} else if (length0 > length1) {
			return -1;
		} else {
			return 0;			
		}
	}
	
	inline public static function compareLengths(edge0:LineSegment, edge1:LineSegment):Int {
		return - compareLengths_MAX(edge0, edge1);
	}

	public var p0:Point;
	public var p1:Point;
	
	public function new(p0:Point, p1:Point)	{
		this.p0 = p0;
		this.p1 = p1;
	}
	
}