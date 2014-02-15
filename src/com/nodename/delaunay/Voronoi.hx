/*
 * The author of this software is Steven Fortune.  Copyright (c) 1994 by AT&T
 * Bell Laboratories.
 * Permission to use, copy, modify, and distribute this software for any
 * purpose without fee is hereby granted, provided that this entire notice
 * is included in all copies of any software which is or includes a copy
 * or modification of this software and in all copies of the supporting
 * documentation for such software.
 * THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT ANY EXPRESS OR IMPLIED
 * WARRANTY.  IN PARTICULAR, NEITHER THE AUTHORS NOR AT&T MAKE ANY
 * REPRESENTATION OR WARRANTY OF ANY KIND CONCERNING THE MERCHANTABILITY
 * OF THIS SOFTWARE OR ITS FITNESS FOR ANY PARTICULAR PURPOSE.
 */


package com.nodename.delaunay;

import com.nodename.geom.Circle;
import com.nodename.geom.LineSegment;
import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import com.nodename.delaunay.SelectHelper;

using com.nodename.delaunay.ArrayHelper;

class Voronoi {
	private var _sites:SiteList;
	private var _sitesIndexedByLocation:Map<Point, Site>;
	private var _triangles:Array<Triangle>;
	private var _edges:Array<Edge>;

	
	// TODO generalize this so it doesn't have to be a rectangle;
	// then we can make the fractal voronois-within-voronois
	private var _plotBounds:Rectangle;
	public function getPlotBounds():Rectangle
	{
		return _plotBounds;
	}
	
	public function dispose(): Void {
		var i, n:Int;
		if (_sites != null)
		{
			_sites.dispose();
			_sites = null;
		}
		if (_triangles != null)
		{
			n = _triangles.length;
			for (i in 0...n)
			{
				_triangles[i].dispose();
			}
			_triangles.clear();
			_triangles = null;
		}
		if (_edges != null)
		{
			n = _edges.length;
			for (i in 0...n)
			{
				_edges[i].dispose();
			}
			_edges.clear();
			_edges = null;
		}
		_plotBounds = null;
		_sitesIndexedByLocation = null;
	}
	
	public function new(points:Array<Point>, colors:Array<Int>, plotBounds:Rectangle)
	{
		_sites = new SiteList();
		_sitesIndexedByLocation = new Map<Point, Site>();
		addSites(points, colors);
		_plotBounds = plotBounds;
		_triangles = new Array<Triangle>();
		_edges = new Array<Edge>();
		fortunesAlgorithm();
	}
	
	private function addSites(points:Array<Point>, colors:Array<Int>):Void
	{
		var length:Int = points.length;
		for (i in 0 ... length)
		{
			addSite(points[i], colors!=null ? colors[i] : 0, i);
		}
	}
	
	private function addSite(p:Point, color:Int, index:Int):Void
	{
		var weight:Float = Math.random() * 100;
		var site:Site = Site.create(p, index, weight, color);
		_sites.push(site);
		_sitesIndexedByLocation[p] = site;
	}
	
	public function region(p:Point):Array<Point>
	{
		var site:Site = _sitesIndexedByLocation[p];
		if (site == null)
		{
			return new Array<Point>();
		}
		return site.region(_plotBounds);
	}
	
	public function neighborSitesForSite(coord:Point):Array<Point>
	{
		var points:Array<Point> = new Array<Point>();
		var site:Site = _sitesIndexedByLocation[coord];
		if (site == null)
		{
			return points;
		}
		var sites:Array<Site> = site.neighborSites();
		var neighbor:Site;
		for (neighbor in sites)
		{
			points.push(neighbor.coord);
		}
		return points;
	}

	public function circles():Array<Circle>
	{
		return _sites.circles();
	}
	
	public function edges() : Array<Edge> {
		return _edges;
	}

	public function sites() : SiteList {
		return _sites;
	}
	
	public function voronoiBoundaryForSite(coord:Point):Array<LineSegment>
	{
		return SelectHelper.visibleLineSegments(SelectHelper.selectEdgesForSitePoint(coord, _edges));
	}

	public function delaunayLinesForSite(coord:Point):Array<LineSegment>
	{
		return SelectHelper.delaunayLinesForEdges(SelectHelper.selectEdgesForSitePoint(coord, _edges));
	}
	
	public function voronoiDiagram():Array<LineSegment>
	{
		return SelectHelper.visibleLineSegments(_edges);
	}
	
	public function delaunayTriangulation(keepOutMask:BitmapData = null):Array<LineSegment>
	{
		return SelectHelper.delaunayLinesForEdges(SelectHelper.selectNonIntersectingEdges(keepOutMask, _edges));
	}
	
	public function hull():Array<LineSegment>
	{
		return SelectHelper.delaunayLinesForEdges(hullEdges());
	}
	
	inline static function myTest(edge:Edge):Bool
	{
		return edge.isPartOfConvexHull();
	}
	
	private function hullEdges():Array<Edge> {
		return _edges.filter(myTest);	
	}

	public function hullPointsInOrder():Array<Point>
	{
		var hullEdges:Array<Edge> = hullEdges();
		
		var points:Array<Point> = new Array<Point>();
		if (hullEdges.length == 0)
		{
			return points;
		}
		
		var reorderer:EdgeReorderer = new EdgeReorderer(hullEdges, EdgeReorderer.edgeToLeftSite, EdgeReorderer.edgeToRightSite);
		hullEdges = reorderer.edges;
		var orientations:Array<LR> = reorderer.edgeOrientations;
		reorderer.dispose();
		
		var orientation:LR;

		var n:Int = hullEdges.length;
		for (i in 0...n)
		{
			var edge:Edge = hullEdges[i];
			orientation = orientations[i];
			points.push(edge.site(orientation).coord);
		}
		return points;
	}
	
	public function spanningTree(type:String = "minimum", keepOutMask:BitmapData = null):Array<LineSegment>	{
		var edges = SelectHelper.selectNonIntersectingEdges(keepOutMask, _edges);
		var segments = SelectHelper.delaunayLinesForEdges(edges);
		return Kruskal.kruskal(segments, type);
	}

	public function regions():Array<Array<Point>>
	{
		return _sites.regions(_plotBounds);
	}
	
	public function siteColors(referenceImage:BitmapData = null):Array<Int>
	{
		return _sites.siteColors(referenceImage);
	}
	
	/**
	 * 
	 * @param proximityMap a BitmapData whose regions are filled with the site index values; see PlanePointsCanvas::fillRegions()
	 * @param x
	 * @param y
	 * @return coordinates of nearest Site to (x, y)
	 * 
	 */
	inline public function nearestSitePoint(proximityMap:BitmapData, x:Int, y:Int):Point {
		return _sites.nearestSitePoint(proximityMap, x, y);
	}
	
	inline public function siteCoords():Array<Point> {
		return _sites.siteCoords();
	}

	private function fortunesAlgorithm():Void {
		
		var newSite:Site;
		var newintstar:Point = null;
		
		var dataBounds = _sites.getSitesBounds();
		
		var sqrt_nsites = Std.int(Math.sqrt(_sites.length + 4));
		var heap = new HalfedgePriorityQueue(dataBounds.y, dataBounds.height, sqrt_nsites);
		var edgeList = new EdgeList(dataBounds.x, dataBounds.width, sqrt_nsites);
		var halfEdges = new Array<Halfedge>();
		var vertices = new Array<Vertex>();
		
		var bottomMostSite:Site = _sites.next();
		
		var leftRegion = function(he:Halfedge):Site {
			var edge:Edge = he.edge;
			if (edge == null)
			{
				return bottomMostSite;
			}
			return edge.site(he.leftRight);
		}
		
		var rightRegion = function(he:Halfedge):Site {
			var edge:Edge = he.edge;
			if (edge == null)
			{
				return bottomMostSite;
			}
			return edge.site(LR.other(he.leftRight));
		}
		
		newSite = _sites.next();
		
		while (true) {
			
			if (heap.empty() == false) {
				newintstar = heap.min();
			}
			
			if (newSite != null &&  (heap.empty() || isInf(newSite, newintstar))) {
				
				/* new site is smallest */
				//trace("smallest: new site " + newSite);
//				trace("edgeList" + edgeList);
				// Step 8:
				var lbnd = edgeList.edgeListLeftNeighbor(newSite.coord);	// the Halfedge just to the left of newSite
				var rbnd = lbnd.edgeListRightNeighbor;		// the Halfedge just to the right
				var bottomSite = rightRegion(lbnd);		// this is the same as leftRegion(rbnd)
				// this Site determines the region containing the new site
				//trace("new Site is in region of existing site: " + bottomSite);
				
				// Step 9:
				var edge = Edge.createBisectingEdge(bottomSite, newSite);
				//trace("new edge: " + edge);
				_edges.push(edge);
				
				var bisector = Halfedge.create(edge, LR.LEFT);
				halfEdges.push(bisector);
				// inserting two Halfedges into edgeList constitutes Step 10:
				// insert bisector to the right of lbnd:
				edgeList.insert(lbnd, bisector);
				
				// first half of Step 11:
				var vertex = Vertex.intersect(lbnd, bisector);
				if (vertex != null)  {
					heap.remove(lbnd);

					vertices.push(vertex);
					lbnd.vertex = vertex;
					lbnd.ystar = vertex.y + newSite.dist(vertex);
					heap.insert(lbnd);
				}
				
				lbnd = bisector;
				bisector = Halfedge.create(edge, LR.RIGHT);
				halfEdges.push(bisector);
				// second Halfedge for Step 10:
				// insert bisector to the right of lbnd:
				edgeList.insert(lbnd, bisector);
				
				// second half of Step 11:
				var vertex = Vertex.intersect(bisector, rbnd);
				if (vertex != null) {
					vertices.push(vertex);
					bisector.vertex = vertex;
					bisector.ystar = vertex.y + newSite.dist(vertex);
					heap.insert(bisector);	
				}
				
				newSite = _sites.next();	
			} else if (heap.empty() == false) {
				
				/* intersection is smallest */
				var lbnd = heap.extractMin();
				var llbnd = lbnd.edgeListLeftNeighbor;
				var rbnd = lbnd.edgeListRightNeighbor;
				var rrbnd = rbnd.edgeListRightNeighbor;
				var bottomSite = leftRegion(lbnd);
				var topSite = rightRegion(rbnd);
				// these three sites define a Delaunay triangle
				// (not actually using these for anything...)
				//_triangles.push(new Triangle(bottomSite, topSite, rightRegion(lbnd)));
				
				var v = lbnd.vertex;
				v.setIndex();
				lbnd.edge.setVertex(lbnd.leftRight, v);
				rbnd.edge.setVertex(rbnd.leftRight, v);
				edgeList.remove(lbnd); 
				heap.remove(rbnd);
				edgeList.remove(rbnd); 
				
				var leftRight = LR.LEFT;
				if (bottomSite.y > topSite.y) {
					var tempSite = bottomSite;
					bottomSite = topSite;
					topSite = tempSite;
					leftRight = LR.RIGHT;
				}
				
				var edge = Edge.createBisectingEdge(bottomSite, topSite);
				_edges.push(edge);
				var bisector = Halfedge.create(edge, leftRight);
				halfEdges.push(bisector);
				edgeList.insert(llbnd, bisector);
				edge.setVertex(LR.other(leftRight), v);
				var vertex = Vertex.intersect(llbnd, bisector);
				if (vertex != null) {
					heap.remove(llbnd);

					vertices.push(vertex);
					llbnd.vertex = vertex;
					llbnd.ystar = vertex.y + bottomSite.dist(vertex);
					heap.insert(llbnd);
				}
				vertex = Vertex.intersect(bisector, rrbnd);
				if (vertex != null) {
					
					vertices.push(vertex);
					bisector.vertex = vertex;
					bisector.ystar = vertex.y + bottomSite.dist(vertex);
					heap.insert(bisector);
				}
			} else {
				break;
			}
		}
				
		// heap should be empty now
		heap.dispose();
		edgeList.dispose();
		
		for (halfEdge in halfEdges) {
			halfEdge.reallyDispose();
		}
		halfEdges.clear();
		
		// we need the vertices to clip the edges
		for (edge in _edges) {
			edge.clipVertices(_plotBounds);
		}
		// but we don't actually ever use them again!
		for (vertex in vertices) {
			vertex.dispose();
		}
		vertices.clear();
	}
	

	public inline static function isInf(s1:Site, s2:Point) : Bool {
		return (s1.y < s2.y) || (s1.y == s2.y && s1.x < s2.x);
	}
	public inline static function isInfSite(s1:Site, s2:Site) : Bool {
		return (s1.y < s2.y) || (s1.y == s2.y && s1.x < s2.x);
	}
	
	public static function compareByYThenX(s1:Site, s2:Site):Int {
	/*
		return 
			(s1.y < s2.y)? -1 :(
			(s1.y > s2.y)? 1:(
			(s1.x < s2.x)? -1:(
			(s1.x > s2.x)? 1: 0)));
	*/		
		if (s1.y < s2.y) return -1;
		if (s1.y > s2.y) return 1;
		if (s1.x < s2.x) return -1;
		if (s1.x > s2.x) return 1;
		return 0;
	}

}
