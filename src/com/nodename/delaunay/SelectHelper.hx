package com.nodename.delaunay;

import com.nodename.geom.Point;
import com.nodename.geom.LineSegment;


class SelectHelper {

	
	public static function visibleLineSegments(edges:Array<Edge>):Array<LineSegment>
	{
		var segments = new Array<LineSegment>();
	
		for (edge in edges) {
			if (edge.visible) {
				var p1 = edge.clippedEnds(LR.LEFT);
				var p2 = edge.clippedEnds(LR.RIGHT);
				segments.push(new LineSegment(p1, p2));
			}
		}
		
		return segments;
	}
	
	public static function selectEdgesForSitePoint(coord:Point, edgesToTest:Array<Edge>):Array<Edge>
	{
		return edgesToTest.filter(
			function (edge:Edge)
				return ((edge.leftSite != null && edge.leftSite.coord == coord) ||  (edge.rightSite != null && edge.rightSite.coord == coord))
		);
	}	
	
	public static function delaunayLinesForEdges(edges:Array<Edge>):Array<LineSegment>
	{
		var segments = new Array<LineSegment>();
		for (edge in edges) {
			segments.push(edge.delaunayLine());
		}
		return segments;
	}	
	
}
	
