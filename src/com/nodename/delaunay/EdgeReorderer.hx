package com.nodename.delaunay;


class EdgeReorderer {
	
	public var edges(get, null):Array<Edge>;
	inline private function get_edges():Array<Edge> {
		return edges;
	}
	
	public var edgeOrientations(get, null):Array<LR>;
	inline private function get_edgeOrientations():Array<LR> {
		return edgeOrientations;
	}
	
	inline public static function edgeToLeftVertex(ed : Edge) : ICoord { return ed.leftVertex;}
	inline public static function edgeToLeftSite(ed : Edge) : ICoord { return ed.leftSite;}
	inline public static function edgeToRightVertex(ed : Edge) : ICoord { return ed.rightVertex;}
	inline public static function edgeToRightSite(ed : Edge) : ICoord { return ed.rightSite;}
	
	// TODO: use a ADT to represent criterion.
	public function new(origEdges:Array<Edge>, leftCoord: Edge -> ICoord, rightCoord: Edge -> ICoord) {
		edges = new Array<Edge>();
		edgeOrientations = new Array<LR>();
		if (origEdges.length > 0)
		{
			edges = reorderEdges(origEdges, leftCoord, rightCoord);
		}
	}
	
	public function dispose():Void
	{
		edges = null;
		edgeOrientations = null;
	}

	private function reorderEdges(origEdges:Array<Edge>, leftCoord: Edge -> ICoord, rightCoord: Edge -> ICoord):Array<Edge> {
		var i:Int;
		var j:Int;
		var n:Int = origEdges.length;
		var edge:Edge;
		// we're going to reorder the edges in order of traversal
		var done:Array<Bool> = new Array<Bool>();
		done[n - 1] = false;
		var nDone:Int = 0;
		for (b in done) {
			b = false;
		}
		var newEdges:Array<Edge> = new Array<Edge>();
		
		i = 0;
		edge = origEdges[i];
		newEdges.push(edge);
		edgeOrientations.push(LR.LEFT);
		var firstPoint:ICoord = leftCoord(edge);
		var lastPoint:ICoord = rightCoord(edge);
		
		if (firstPoint == Vertex.VERTEX_AT_INFINITY || lastPoint == Vertex.VERTEX_AT_INFINITY)
		{
			return new Array<Edge>();
		}
		
		done[i] = true;
		++nDone;
		
		while (nDone < n)
		{
			for (i in 1...n)
			{
				if (done[i])
				{
					continue;
				}
				edge = origEdges[i];
				var leftPoint:ICoord = leftCoord(edge);
				var rightPoint:ICoord = rightCoord(edge);
				
				if (leftPoint == Vertex.VERTEX_AT_INFINITY || rightPoint == Vertex.VERTEX_AT_INFINITY)
				{
					return new Array<Edge>();
				}
				if (leftPoint == lastPoint)
				{
					lastPoint = rightPoint;
					edgeOrientations.push(LR.LEFT);
					newEdges.push(edge);
					done[i] = true;
				}
				else if (rightPoint == firstPoint)
				{
					firstPoint = leftPoint;
					edgeOrientations.unshift(LR.LEFT);
					newEdges.unshift(edge);
					done[i] = true;
				}
				else if (leftPoint == firstPoint)
				{
					firstPoint = rightPoint;
					edgeOrientations.unshift(LR.RIGHT);
					newEdges.unshift(edge);
					done[i] = true;
				}
				else if (rightPoint == lastPoint)
				{
					lastPoint = leftPoint;
					edgeOrientations.push(LR.RIGHT);
					newEdges.push(edge);
					done[i] = true;
				}
				if (done[i])
				{
					++nDone;
				}
			}
		}
		
		return newEdges;
	}

}