package com.nodename.delaunay;

import com.nodename.geom.Circle;
import com.nodename.delaunay.IDisposable;
import com.nodename.geom.Point;
import com.nodename.geom.Rectangle;

using com.nodename.delaunay.ArrayHelper;


class SiteList implements IDisposable {
	private var _sites:Array<Site>;
	private var _currentIndex:Int;
	
	private var _sorted:Bool;
	
	public function new()
	{
		_sites = new Array<Site>();
		_sorted = false;
	}
	
	public function dispose():Void
	{
		if (_sites != null)
		{
			for (site in _sites)
			{
				site.dispose();
			}
			_sites.clear();
			_sites = null;
		}
	}
	
	public function push(site:Site):Int
	{
		_sorted = false;
		return _sites.push(site);
	}
	
	public var length(get, null) : Int;
	inline private function get_length():Int {
		return _sites.length;
	}
	
	public function next():Site
	{
		if (_sorted == false)
		{
			throw "SiteList::next():  sites have not been sorted";
		}
		if (_currentIndex < _sites.length)
		{
			return _sites[_currentIndex++];
		}
		else
		{
			return null;
		}
	}

	public function getSitesBounds():Rectangle {
		if (_sorted == false)
		{
			Site.sortSites(_sites);
			_currentIndex = 0;
			_sorted = true;
		}
		var xmin:Float;
		var xmax:Float;
		var ymin:Float;
		var ymax:Float;
		if (_sites.length == 0)
		{
			return new Rectangle(0, 0, 0, 0);
		}
		
		xmin = Math.POSITIVE_INFINITY;
		xmax = Math.NEGATIVE_INFINITY;
		for (site in _sites)
		{
			if (site.x < xmin)
			{
				xmin = site.x;
			}
			if (site.x > xmax)
			{
				xmax = site.x;
			}
		}
		// here's where we assume that the sites have been sorted on y:
		ymin = _sites[0].y;
		ymax = _sites[_sites.length - 1].y;
		
		return new Rectangle(xmin, ymin, xmax - xmin, ymax - ymin);
	}

	public function siteColors():Array<Int>
	{
		var colors = new Array<Int>();
		for (site in _sites)
		{
			colors.push(site.color);
		}
		return colors;
	}

	public function siteCoords():Array<Point>
	{
		var coords:Array<Point> = new Array<Point>();
		for (site in _sites)
		{
			coords.push(site.coord);
		}
		return coords;
	}

	public function sites():Array<Site> {
		return _sites;
	}
	
	/**
	 * 
	 * @return the largest circle centered at each site that fits in its region;
	 * if the region is infinite, return a circle of radius 0.
	 * 
	 */
	public function circles():Array<Circle>
	{
		var circles = new Array<Circle>();
		for (site in _sites) {
			var nearestEdge = site.nearestEdge();
			
			var radius = (!nearestEdge.isPartOfConvexHull())? (nearestEdge.sitesDistance() * 0.5): 0;
			circles.push(new Circle(site.x, site.y, radius));
		}
		return circles;
	}

	public function regions(plotBounds:Rectangle):Array<Array<Point>> {
		var regions = new Array<Array<Point>>();
		for (site in _sites)
		{
			regions.push(site.region(plotBounds));
		}
		return regions;
	}

	/**
	 * 
	 * @param x
	 * @param y
	 * @return coordinates of nearest Site to (x, y)
	 * 
	 */
	public function nearestSitePoint(x:Int, y:Int):Point
	{
		var res = null;
		var p = new Point(x, y);
		var minDistSqr = Math.POSITIVE_INFINITY;
		
		for (site in _sites) {
			var q = site.coord;
			var distSqr = Point.distanceSquared(p, q);
			if (distSqr < minDistSqr) {
				minDistSqr = distSqr;
				res = site;
			}
		}
		
		return res != null ? res.coord : null;
	}
}
