package;

import js.Browser.*;

import com.nodename.delaunay.*;
import com.nodename.geom.*;

/**
 * hxDelaunay haxe js demo.
 *
 * @author @MatthijsKamstra
 */
class DemoJs {

	var container : js.html.DivElement;
	var canvas : js.html.CanvasElement;
	var context : js.html.CanvasRenderingContext2D;

	var displayWidth : Int  = 500;
	var displayHeight : Int  = 500;

	static function main () document.addEventListener("DOMContentLoaded", function(e) new DemoJs());

	public function new () {
		setup();
		generate();
	}

	function setup(){
		container = document.createDivElement();
		container.id = 'delaunay';
		container.className = 'container';
		document.body.appendChild(container);

		canvas = document.createCanvasElement();
		canvas.width = displayWidth;
		canvas.height = displayHeight;
		canvas.className = 'canvasOne';
		canvas.id = 'canvasOne';
		container.appendChild(canvas);

		context = canvas.getContext2d();

		canvas.onclick = onClickHandler;
	}

	function onClickHandler (e : js.html.MouseEvent){
		context.clearRect(0,0,canvas.width, canvas.height);
		generate();
		e.preventDefault();
	}

	function generate(){
		var rect = new Rectangle(0, 0, canvas.width, canvas.height);
		// first random set of points
		var points = new Array<Point>();
		for (i in 0...25) {
			points.push(new Point(Math.random() * rect.width, Math.random() * rect.height));
		}

		var voronoi : Voronoi = new Voronoi(points, null, rect);
		var regions:Array<Array<Point>> = [for (p in points) voronoi.region(p)];
		var sortedRegions:Array<Array<Point>> = voronoi.regions();
		// var triangles:Array<LineSegment> = voronoi.delaunayTriangulation();
		// var hull:Array<LineSegment> = voronoi.hull();
		// var tree:Array<LineSegment> = voronoi.spanningTree();

		for (i in 0 ... voronoi.triangles().length)
		{
			var tri : Triangle = voronoi.triangles()[i];
			var sitesArr : Array<Site> = tri.sites;
			context.beginPath();
			context.moveTo(sitesArr[0].coord.x, sitesArr[0].coord.y);
			context.lineTo(sitesArr[1].coord.x, sitesArr[1].coord.y);
			context.lineTo(sitesArr[2].coord.x, sitesArr[2].coord.y);

			var color = 'rgba(' + Std.random(255) + ',' + Std.random(255) + ',' + Std.random(255) + ', 1)';

			context.closePath();
			context.fillStyle = color;
			context.lineWidth = 0.5;
			context.strokeStyle = color;
			context.stroke();
			context.fill();
		}

		/*
		for (i in 0 ... points.length) {
			var p = points[i];
			context.beginPath();
			context.arc(p.x, p.y, 2, 0, 2 * Math.PI, false);
			context.fillStyle = 'red';
			context.fill();
			context.closePath();
		}
		*/

	}

}