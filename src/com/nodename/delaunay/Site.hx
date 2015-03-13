package com.nodename.delaunay;

import com.nodename.geom.Polygon;
import com.nodename.geom.Winding;
import com.nodename.geom.Point;
import com.nodename.geom.Rectangle;

using com.nodename.delaunay.ArrayHelper;


class Site implements ICoord
{
	private static var _pool:Array<Site> = new Array<Site>();
	public static function create(p:Point, index:Int, weight:Float, color:Int):Site {
		if (_pool.length > 0)
		{
			return _pool.pop().init(p, index, weight, color);
		}
		else
		{
			return new Site(p, index, weight, color);
		}
	}
	
	public inline static function sortSites(sites:Array<Site>):Void {
		sites.sort(Site.compare);
	}

	/**
	 * sort sites on y, then x, coord
	 * also change each site's _siteIndex to match its new position in the list
	 * so the _siteIndex can be used to identify the site for nearest-neighbor queries
	 * 
	 * haha "also" - means more than one responsibility...
	 * 
	 */
	
	private static function compare(s1:Site, s2:Site):Int {
		var returnValue:Int = Voronoi.compareByYThenX(s1, s2);
		
		// swap _siteIndex values if necessary to match new ordering:
		var tempIndex:Int;
		if (returnValue == -1)
		{
			if (s1._siteIndex > s2._siteIndex)
			{
				tempIndex = s1._siteIndex;
				s1._siteIndex = s2._siteIndex;
				s2._siteIndex = tempIndex;
			}
		}
		else if (returnValue == 1)
		{
			if (s2._siteIndex > s1._siteIndex)
			{
				tempIndex = s2._siteIndex;
				s2._siteIndex = s1._siteIndex;
				s1._siteIndex = tempIndex;
			}
			
		}
		
		return returnValue;
	}
	


	private static var EPSILON = .005;
	private static function closeEnough(p0:Point, p1:Point):Bool {
		var dx2 = (p0.x - p1.x) * (p0.x - p1.x);
		var dy2 = (p0.y - p1.y) * (p0.y - p1.y);
		return Math.sqrt(dx2 + dy2) < EPSILON;
	}
	
	public var coord(get, null) : Point;
	inline private function get_coord():Point {
		return coord;
	}
	
	public var color:Int;
	public var weight:Float = 0;
	
	private var _siteIndex:Int;
	
	// the edges that define this Site's Voronoi region:
	public var edges(get, null):Array<Edge>;
	inline private function get_edges():Array<Edge>
	{
		return edges;
	}
	// which end of each edge hooks up with the previous edge in _edges:
	private var _edgeOrientations:Array<LR>;
	// ordered list of points that define the region clipped to bounds:
	private var _region:Array<Point>;

	// use create instead.
	private function new(p:Point, index:Int, weight:Float, color:Int) {
		init(p, index, weight, color);
	}
	
	private function init(p:Point, index:Int, weight:Float, color:Int):Site
	{
		coord = p;
		_siteIndex = index;
		this.weight = weight;
		this.color = color;
		edges = new Array<Edge>();
		_region = null;
		return this;
	}
	
	public function toString():String
	{
		return "Site " + _siteIndex + ": " + coord;
	}
	
	private function move(p:Point):Void
	{
		clear();
		coord = p;
	}
	
	public function dispose():Void
	{
		coord = null;
		clear();
		_pool.push(this);
	}
	
	private function clear():Void
	{
		if (edges != null)
		{
			edges.clear();
			edges = null;
		}
		if (_edgeOrientations != null)
		{
			_edgeOrientations.clear();
			_edgeOrientations = null;
		}
		if (_region != null)
		{
			_region.clear();
			_region = null;
		}
	}
	
	inline public function addEdge(edge:Edge):Void
	{
		edges.push(edge);
	}
	
	// TODO: Can be optimized.
	public function nearestEdge():Edge
	{
		edges.sort(Edge.compareSitesDistances);
		return edges[0];
	}
	
	public function neighborSites():Array<Site>
	{
		if (edges == null || edges.length == 0)
		{
			return new Array<Site>();
		}
		if (_edgeOrientations == null)
		{ 
			reorderEdges();
		}
		var list = new Array<Site>();
		for (edge in edges)
		{
			list.push(neighborSite(edge));
		}
		return list;
	}
		
	private function neighborSite(edge:Edge):Site
	{
		if (this == edge.leftSite)
		{
			return edge.rightSite;
		}
		if (this == edge.rightSite)
		{
			return edge.leftSite;
		}
		return null;
	}
	
	public function region(clippingBounds:Rectangle):Array<Point> {
		if (edges == null || edges.length == 0)
		{
			return new Array<Point>();
		}
		if (_edgeOrientations == null)
		{
			reorderEdges();
			_region = clipToBounds(clippingBounds);
			if ((new Polygon(_region)).winding() == Winding.CLOCKWISE)
			{
				_region.reverse();
			}
		}
		return _region;
	}
	
	private function reorderEdges():Void
	{
		//trace("edges:", edges);
		var reorderer = new EdgeReorderer(edges, EdgeReorderer.edgeToLeftVertex, EdgeReorderer.edgeToRightVertex);
		edges = reorderer.edges;
		//trace("reordered:", edges);
		_edgeOrientations = reorderer.edgeOrientations;
		reorderer.dispose();
	}
	
	private function clipToBounds(bounds:Rectangle):Array<Point>
	{
		var points:Array<Point> = new Array<Point>();
		var n:Int = edges.length;
		var i:Int = 0;
		var edge:Edge;
		while (i < n && (edges[i].visible == false))
		{
			++i;
		}
		
		if (i == n)
		{
			// no edges visible
			return new Array<Point>();
		}
		edge = edges[i];
		var orientation:LR = _edgeOrientations[i];
		points.push(edge.clippedEnds(orientation));
		points.push(edge.clippedEnds(LR.other(orientation)));
		
		for (j in (i + 1)...n)
		{
			edge = edges[j];
			if (edge.visible == false)
			{
				continue;
			}
			connect(points, j, bounds);
		}
		// close up the polygon by adding another corner point of the bounds if needed:
		connect(points, i, bounds, true);
		
		return points;
	}
	
	private function connect(points:Array<Point>, j:Int, bounds:Rectangle, closingUp:Bool = false):Void
	{
		var rightPoint = points[points.length - 1];
		var newEdge = edges[j];
		var newOrientation:LR = _edgeOrientations[j];
		// the point that  must be connected to rightPoint:
		var newPoint = newEdge.clippedEnds(newOrientation);
		if (!closeEnough(rightPoint, newPoint))
		{
			// The points do not coincide, so they must have been clipped at the bounds;
			// see if they are on the same border of the bounds:
			if (rightPoint.x != newPoint.x
			&&  rightPoint.y != newPoint.y)
			{
				// They are on different borders of the bounds;
				// insert one or two corners of bounds as needed to hook them up:
				// (NOTE this will not be correct if the region should take up more than
				// half of the bounds rect, for then we will have gone the wrong way
				// around the bounds and included the smaller part rather than the larger)
				var rightCheck:Int = BoundsCheck.check(rightPoint, bounds);
				var newCheck:Int = BoundsCheck.check(newPoint, bounds);
				var px;
				var py;
				if (rightCheck & BoundsCheck.RIGHT != 0)
				{
					px = bounds.right;
					if (newCheck & BoundsCheck.BOTTOM != 0)
					{
						py = bounds.bottom;
						points.push(new Point(px, py));
					}
					else if (newCheck & BoundsCheck.TOP != 0)
					{
						py = bounds.top;
						points.push(new Point(px, py));
					}
					else if (newCheck & BoundsCheck.LEFT != 0)
					{
						if (rightPoint.y - bounds.y + newPoint.y - bounds.y < bounds.height)
						{
							py = bounds.top;
						}
						else
						{
							py = bounds.bottom;
						}
						points.push(new Point(px, py));
						points.push(new Point(bounds.left, py));
					}
				}
				else if (rightCheck & BoundsCheck.LEFT != 0)
				{
					px = bounds.left;
					if (newCheck & BoundsCheck.BOTTOM != 0)
					{
						py = bounds.bottom;
						points.push(new Point(px, py));
					}
					else if (newCheck & BoundsCheck.TOP != 0)
					{
						py = bounds.top;
						points.push(new Point(px, py));
					}
					else if (newCheck & BoundsCheck.RIGHT != 0)
					{
						if (rightPoint.y - bounds.y + newPoint.y - bounds.y < bounds.height)
						{
							py = bounds.top;
						}
						else
						{
							py = bounds.bottom;
						}
						points.push(new Point(px, py));
						points.push(new Point(bounds.right, py));
					}
				}
				else if (rightCheck & BoundsCheck.TOP != 0)
				{
					py = bounds.top;
					if (newCheck & BoundsCheck.RIGHT != 0)
					{
						px = bounds.right;
						points.push(new Point(px, py));
					}
					else if (newCheck & BoundsCheck.LEFT != 0)
					{
						px = bounds.left;
						points.push(new Point(px, py));
					}
					else if (newCheck & BoundsCheck.BOTTOM != 0)
					{
						if (rightPoint.x - bounds.x + newPoint.x - bounds.x < bounds.width)
						{
							px = bounds.left;
						}
						else
						{
							px = bounds.right;
						}
						points.push(new Point(px, py));
						points.push(new Point(px, bounds.bottom));
					}
				}
				else if (rightCheck & BoundsCheck.BOTTOM != 0)
				{
					py = bounds.bottom;
					if (newCheck & BoundsCheck.RIGHT != 0)
					{
						px = bounds.right;
						points.push(new Point(px, py));
					}
					else if (newCheck & BoundsCheck.LEFT != 0)
					{
						px = bounds.left;
						points.push(new Point(px, py));
					}
					else if (newCheck & BoundsCheck.TOP != 0)
					{
						if (rightPoint.x - bounds.x + newPoint.x - bounds.x < bounds.width)
						{
							px = bounds.left;
						}
						else
						{
							px = bounds.right;
						}
						points.push(new Point(px, py));
						points.push(new Point(px, bounds.top));
					}
				}
			}
			if (closingUp)
			{
				// newEdge's ends have already been added
				return;
			}
			points.push(newPoint);
		}
		var newRightPoint = newEdge.clippedEnds(LR.other(newOrientation));
		if (!closeEnough(points[0], newRightPoint))
		{
			points.push(newRightPoint);
		}
	}
	
	public var x(get, null):Float;
	inline private function get_x() {
		return coord.x;
	}

	public var y(get, null):Float;
	inline private function get_y() {
		return coord.y;
	}
	
	public function dist(p:ICoord)
	{
		var dx2 = (p.coord.x - this.coord.x) * (p.coord.x - this.coord.x);
		var dy2 = (p.coord.y - this.coord.y) * (p.coord.y - this.coord.y);
		return Math.sqrt(dx2 + dy2);
	}

}


@: final class BoundsCheck
{
	public static var TOP:Int = 1;
	public static var BOTTOM:Int = 2;
	public static var LEFT:Int = 4;
	public static var RIGHT:Int = 8;
	
	/**
	 * 
	 * @param point
	 * @param bounds
	 * @return an Int with the appropriate bits set if the Point lies on the corresponding bounds lines
	 * 
	 */
	public static function check(point:Point, bounds:Rectangle):Int
	{
		var value:Int = 0;
		if (point.x == bounds.left)
		{
			value |= LEFT;
		} else if (point.x == bounds.right) {
			value |= RIGHT;
		}
		if (point.y == bounds.top)
		{
			value |= TOP;
		} else if (point.y == bounds.bottom) {
			value |= BOTTOM;
		}
		return value;
	}
	
	private function new()
	{
		throw "BoundsCheck constructor unused";
	}
	
}