package com.nodename.geom;


class Circle {
	public var center:Point;
	public var radius:Float;
	
	public function new(centerX:Float, centerY:Float, radius:Float)
	{
		this.center = new Point(centerX, centerY);
		this.radius = radius;
	}
	
	public function toString():String
	{
		return "Circle (center: " + center + "; radius: " + radius + ")";
	}

}
