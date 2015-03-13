package com.nodename.delaunay;


/**
 * ...
 * @author sledorze
 * @author azrafe7
 */
class ArrayHelper  {

	/**
	 * Empties an array of its' contents
	 * @param array filled array
	 */
	public static inline function clear<T>(array:Array<T>)
	{
	#if (cpp || php)
		array.splice(0, array.length);
	#else
		untyped array.length = 0;
	#end
	}

}