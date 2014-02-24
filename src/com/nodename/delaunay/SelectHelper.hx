package com.nodename.delaunay;

import flash.geom.Point;
import flash.display.BitmapData;

import com.nodename.geom.LineSegment;

#if (!flash)
using net.azrafe7.tools.BitmapDataTools;
#end


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
	
	public static function selectNonIntersectingEdges(keepOutMask:BitmapData, edgesToTest:Array<Edge>):Array<Edge> {
		if (keepOutMask == null)
		{
			return edgesToTest;
		}
		
		var zeroPoint:Point = new Point();
		
		return edgesToTest.filter(
			function (edge:Edge):Bool {
				var delaunayLineBmp = edge.makeDelaunayLineBmp();
				var notIntersecting = !(keepOutMask.hitTest(zeroPoint, 1, delaunayLineBmp, zeroPoint, 1));
				delaunayLineBmp.dispose();
				return notIntersecting;
			}
		);		
	}
	
	public static function selectEdgesForSitePoint(coord:Point, edgesToTest:Array<Edge>):Array<Edge>
	{
		return edgesToTest.filter(
			function (edge:Edge)
				return ((edge.leftSite!=null && edge.leftSite.coord == coord) ||  (edge.rightSite!=null && edge.rightSite.coord == coord))
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
	
