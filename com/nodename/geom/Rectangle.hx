package com.nodename.geom;


class Rectangle {

	public var x:Float;
	public var y:Float;
	public var width:Float;
	public var height:Float;
	
	public function new(x:Float = 0, y:Float = 0, w:Float = 0, h:Float = 0) {
		this.x = x;
		this.y = y;
		this.width = w;
		this.height = h;
	}
	
	public var left(get, never):Float;
	inline private function get_left():Float {
		return x;
	}
	
	public var right(get, never):Float;
	inline private function get_right():Float {
		return x + width;
	}
	
	public var top(get, never):Float;
	inline private function get_top():Float {
		return y;
	}
	
	public var bottom(get, never):Float;
	inline private function get_bottom():Float {
		return y + height;
	}
	
	public function setTo(x:Float, y:Float, w:Float, h:Float):Rectangle {
		this.x = x;
		this.y = y;
		this.width = w;
		this.height = h;
		return this;
	}

	public function clone():Rectangle {
		return new Rectangle(x, y, width, height);
	}
	
	public function toString():String {
		return '(${x}, ${y}, ${width}x${height})';
	}
}