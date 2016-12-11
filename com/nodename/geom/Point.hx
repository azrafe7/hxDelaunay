package com.nodename.geom;


class Point {

	public var x:Float;
	public var y:Float;
	
	public function new(x:Float = 0, y:Float = 0) {
		this.x = x;
		this.y = y;
	}
	
	public function setTo(x:Float, y:Float):Point {
		this.x = x;
		this.y = y;
		return this;
	}
	
	public function normalize(length:Float):Point {
		var denom = Math.sqrt(x * x + y * y);
		if (denom != 0) {
			var f = length / denom;
			x *= f;
			y *= f;
		}
		return this;
	}
	
	public function clone():Point {
		return new Point(x, y);
	}
	
	public function toString():String {
		return '(${x}, ${y})';
	}

	static public function distance(p:Point, q:Point):Float {
		return Math.sqrt(distanceSquared(p, q));
	}
	
	 static public function distanceSquared(p:Point, q:Point):Float {
		var dx = p.x - q.x;
		var dy = p.y - q.y;
		return dx * dx + dy * dy;
	}
}