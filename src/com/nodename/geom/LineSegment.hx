package com.nodename.geom;

import com.nodename.geom.Point;

class LineSegment  {
	public static function compareLengths_MAX(segment0:LineSegment, segment1:LineSegment):Int {
		var length0 = Point.distanceSquared(segment0.p0, segment0.p1);
		var length1 = Point.distanceSquared(segment1.p0, segment1.p1);
		if (length0 < length1) {
			return 1;
		} else if (length0 > length1) {
			return -1;
		} else {
			return 0;			
		}
	}
	
	 public static function compareLengths(edge0:LineSegment, edge1:LineSegment):Int {
		return - compareLengths_MAX(edge0, edge1);
	}

	public var p0:Point;
	public var p1:Point;
	
	public function new(p0:Point, p1:Point)	{
		this.p0 = p0;
		this.p1 = p1;
	}
	
}