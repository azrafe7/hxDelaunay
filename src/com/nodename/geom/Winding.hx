package com.nodename.geom;

class Winding
{
	public static var CLOCKWISE:Winding = new Winding(PrivateConstructorEnforcer, "clockwise");
	public static var COUNTERCLOCKWISE:Winding = new Winding(PrivateConstructorEnforcer, "counterclockwise");
	public static var NONE:Winding = new Winding(PrivateConstructorEnforcer, "none");
	
	private var _name:String;
	
	public function new(lock:Class<Dynamic>, name:String) {
		if (lock != PrivateConstructorEnforcer)
		{
			throw "Invalid constructor access";
		}
		_name = name;
	}
	
	public function toString():String
	{
		return _name;
	}
}


class PrivateConstructorEnforcer { }
