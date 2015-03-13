package com.nodename.delaunay;

import com.nodename.geom.LineSegment;
import com.nodename.geom.Point;
import com.nodename.geom.Rectangle;



/**
 * The line segment connecting the two Sites is part of the Delaunay triangulation;
 * the line segment connecting the two Vertices is part of the Voronoi diagram
 * @author ashaw
 * 
 */
class Edge
{
	private static var _pool:Array<Edge> = new Array<Edge>();

	private static var _nedges:Int = 0;
	
	public static var DELETED:Edge = new Edge();
	
	/**
	 * This is the only way to create a new Edge 
	 * @param site0
	 * @param site1
	 * @return 
	 * 
	 */
	public static function createBisectingEdge(site0:Site, site1:Site):Edge {
	
		var dx = site1.x - site0.x;
		var dy = site1.y - site0.y;
		var absdx = dx > 0 ? dx : -dx;
		var absdy = dy > 0 ? dy : -dy;
		var c = site0.x * dx + site0.y * dy + (dx * dx + dy * dy) * 0.5;

		var a:Float;
		var b:Float;
		if (absdx > absdy)	{
			a = 1.0; b = dy/dx; c /= dx;
		} else {
			b = 1.0; a = dx/dy; c /= dy;
		}
		
		var edge = Edge.create();
	
		edge.leftSite = site0;
		edge.rightSite = site1;
				
		site0.addEdge(edge);
		site1.addEdge(edge);
		
		edge.leftVertex = null;
		edge.rightVertex = null;
		
		edge.a = a;
		edge.b = b;
		edge.c = c;
		//trace("createBisectingEdge: a ", edge.a, "b", edge.b, "c", edge.c);
		
		return edge;
	}

	private static function create():Edge
	{
		var edge:Edge;
		if (_pool.length > 0)
		{
			edge = _pool.pop();
			edge.init();
		}
		else
		{
			edge = new Edge();
		}
		return edge;
	}
	
	public function delaunayLine():LineSegment {
		// draw a line connecting the input Sites for which the edge is a bisector:
		return new LineSegment(leftSite.coord, rightSite.coord);
	}
	
	
	// the equation of the edge: ax + by = c
	public var a:Float = 0;
	public var b:Float = 0;
	public var c:Float = 0;
	
	// the two Voronoi vertices that the edge connects
	// (if one of them is null, the edge extends to infinity)
	public var leftVertex(get, null):Vertex = null;
	inline private function get_leftVertex():Vertex {
		return leftVertex;
	}

	public var rightVertex(get, null):Vertex = null;
	inline private function get_rightVertex():Vertex {
		return rightVertex;
	}
	 
	inline public function vertex(leftRight:LR):Vertex {
		return (leftRight == LR.LEFT) ? leftVertex : rightVertex;
	}
	
	public function setVertex(leftRight:LR, v:Vertex):Void {
		if (leftRight == LR.LEFT) {
			leftVertex = v;
		} else {
			rightVertex = v;
		}
	}
	
	inline public function isPartOfConvexHull():Bool {
		return (leftVertex == null || rightVertex == null);
	}
	
	inline public function sitesDistance():Float {
		return Point.distance(leftSite.coord, rightSite.coord);
	}
	
	static public function compareSitesDistances_MAX(edge0:Edge, edge1:Edge):Int {
		var length0:Float = edge0.sitesDistance();
		var length1:Float = edge1.sitesDistance();
		if (length0 < length1) {
			return 1;
		} else if (length0 > length1) {
			return -1;
		} else {
			return 0;			
		}
	}
	
	inline static public function compareSitesDistances(edge0:Edge, edge1:Edge):Int {
		return -compareSitesDistances_MAX(edge0, edge1);
	}
	
	private var __leftPoint : Point;
	private var __rightPoint : Point;
	
	public function clippedEnds(or : LR) : Point {
		return (or == LR.LEFT)?__leftPoint:__rightPoint;
	}
	
	public function setClippedEnds(or : LR, p : Point) : Void {
		if (or == LR.LEFT)
			__leftPoint = p;
		else
			__rightPoint = p;
	}
	
	// unless the entire Edge is outside the bounds.
	// In that case visible will be false:
	public var visible(get, null): Bool;
	inline private function get_visible():Bool {
		return __leftPoint != null && __rightPoint != null; // _clippedVertices != null;
	}
	
	// the two input Sites for which this Edge is a bisector:		
	public var leftSite : Site;
	public var rightSite : Site;
	
	inline public function site(leftRight:LR):Site {
		return (leftRight == LR.LEFT) ? leftSite : rightSite;
	}
	
	public var _edgeIndex:Int = 0;
	
	public function dispose():Void {
		leftVertex = null;
		rightVertex = null;
		setClippedEnds(LR.LEFT, null);
		setClippedEnds(LR.RIGHT, null);
		
		rightSite = null;
		leftSite = null;
		
		leftSite = null;
		rightSite = null;

		//_sitesDic = null;
		
		_pool.push(this);
	}

	// Should be private
	
	public function new() {
		_edgeIndex = _nedges++;
		init();
	}
	
	private function init():Void
	{	
		__leftPoint = null;
		__rightPoint = null;
		
		leftSite = null;
		rightSite = null;
	}
	
	public function toString():String
	{
		return "Edge " + _edgeIndex + "; sites " + site(LR.LEFT) + ", " + site(LR.RIGHT)
				+ "; endVertices " + (leftVertex != null ? ""+leftVertex.vertexIndex : "null") + ", "
				+ (rightVertex != null ? ""+rightVertex.vertexIndex : "null") + ((leftSite != null)?""+leftSite:"null") + ((rightSite != null)?""+rightSite:"null") + "::";
	}

	/**
	 * Set _clippedVertices to contain the two ends of the portion of the Voronoi edge that is visible
	 * within the bounds.  If no part of the Edge falls within the bounds, leave _clippedVertices null. 
	 * @param bounds
	 * 
	 */
	public function clipVertices(bounds:Rectangle):Void {
		var xmin:Float = bounds.x;
		var ymin:Float = bounds.y;
		var xmax:Float = bounds.right;
		var ymax:Float = bounds.bottom;
		
		var vertex0:Vertex, vertex1:Vertex;
		var x0:Float, x1:Float, y0:Float, y1:Float;
		
		if (a == 1.0 && b >= 0.0)
		{
			vertex0 = rightVertex;
			vertex1 = leftVertex;
		}
		else 
		{
			vertex0 = leftVertex;
			vertex1 = rightVertex;
		}
	
		if (a == 1.0)
		{
			y0 = ymin;
			if (vertex0 != null && vertex0.y > ymin)
			{
				 y0 = vertex0.y;
			}
			if (y0 > ymax)
			{
				return;
			}
			x0 = c - b * y0;
			
			y1 = ymax;
			if (vertex1 != null && vertex1.y < ymax)
			{
				y1 = vertex1.y;
			}
			if (y1 < ymin)
			{
				return;
			}
			x1 = c - b * y1;
			
			if ((x0 > xmax && x1 > xmax) || (x0 < xmin && x1 < xmin))
			{
				return;
			}
			
			if (x0 > xmax)
			{
				x0 = xmax; y0 = (c - x0)/b;
			}
			else if (x0 < xmin)
			{
				x0 = xmin; y0 = (c - x0)/b;
			}
			
			if (x1 > xmax)
			{
				x1 = xmax; y1 = (c - x1)/b;
			}
			else if (x1 < xmin)
			{
				x1 = xmin; y1 = (c - x1)/b;
			}
		}
		else
		{
			x0 = xmin;
			if (vertex0 != null && vertex0.x > xmin)
			{
				x0 = vertex0.x;
			}
			if (x0 > xmax)
			{
				return;
			}
			y0 = c - a * x0;
			
			x1 = xmax;
			if (vertex1 != null && vertex1.x < xmax)
			{
				x1 = vertex1.x;
			}
			if (x1 < xmin)
			{
				return;
			}
			y1 = c - a * x1;
			
			if ((y0 > ymax && y1 > ymax) || (y0 < ymin && y1 < ymin))
			{
				return;
			}
			
			if (y0 > ymax)
			{
				y0 = ymax; x0 = (c - y0)/a;
			}
			else if (y0 < ymin)
			{
				y0 = ymin; x0 = (c - y0)/a;
			}
			
			if (y1 > ymax)
			{
				y1 = ymax; x1 = (c - y1)/a;
			}
			else if (y1 < ymin)
			{
				y1 = ymin; x1 = (c - y1)/a;
			}
		}

		if (vertex0 == leftVertex)
		{
			setClippedEnds(LR.LEFT, new Point(x0, y0));
			setClippedEnds(LR.RIGHT, new Point(x1, y1));
		} else {
			setClippedEnds(LR.RIGHT, new Point(x0, y0));
			setClippedEnds(LR.LEFT, new Point(x1, y1));
		}
	}

}
