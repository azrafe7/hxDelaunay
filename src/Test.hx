package;


import com.nodename.delaunay.Voronoi;
import com.nodename.geom.LineSegment;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.CapsStyle;
import flash.display.Graphics;
import flash.display.LineScaleMode;
import flash.display.Sprite;
import flash.display.Stage;
import flash.events.KeyboardEvent;
import flash.filters.GlowFilter;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.Lib;
import flash.system.System;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.ui.Keyboard;
import openfl.Assets;
import openfl.display.FPS;


using StringTools;

/**
 * hxDelaunay openFL test.
 * 
 * @author azrafe7
 */
class Test extends Sprite {

	private var g:Graphics;

	private var POINT_COLOR:Int = 0x00FF00;
	private var REGION_COLOR:Int = 0x0000FF;
	private var TRIANGLE_COLOR:Int = 0xFF0000;
	private var HULL_COLOR:Int = 0x00FFFF;
	private var TREE_COLOR:Int = 0xA0A010;
	
	private var THICKNESS:Float = 1.5;
	private var ALPHA:Float = .8;

	private var TEXT_COLOR:Int = 0xFFFFFFFF;
	private var TEXT_FONT:String = "_typewriter";
	private var TEXT_SIZE:Float = 12;
	private var TEXT_OUTLINE:GlowFilter = new GlowFilter(0xFF000000, 1, 2, 2, 6);

	private var BOUNDS:Rectangle = new Rectangle(0, 0, 500, 500);
	
	private var voronoi:Voronoi;
	private var nPoints:Int = 25;
	private var points:Array<Point>;
	private var regions:Array<Array<Point>>;
	private var triangles:Array<LineSegment>;
	private var hull:Array<LineSegment>;
	private var tree:Array<LineSegment>;

	private var showPoints:Bool = true;
	private var showRegions:Bool = true;
	private var showTriangles:Bool = false;
	private var showHull:Bool = false;
	private var showTree:Bool = false;
	
	private var text:TextField;
	
	private var TEXT:String =
		"         hxDelaunay \n" +
		"    (ported by azrafe7)\n\n\n" +
		"\n" +
		"          TOGGLE:\n\n" +
		" 1  points        : |POINTS|\n" +
		" 2  regions       : |REGIONS|\n" + 
		" 3  triangles     : |TRIANGLES|\n" +
		" 4  convex hull   : |HULL|\n" + 
		" 5  spanning tree : |TREE|\n" +
		"\n\n" +
		"        POINTS: (|NPOINTS|)\n\n" +
		" +  add\n" +
		" -  remove\n\n" +
		" R  randomize\n";
	
		
	public function new () {
		super ();

		g = graphics;
		g.lineStyle(THICKNESS, TEXT_COLOR, ALPHA);

		addChild(text = getTextField(TEXT, BOUNDS.width + 10, 20));
		
		points = new Array<Point>();
		// first random set
		for (i in 0...nPoints) points.push(new Point(Math.random() * BOUNDS.width, Math.random() * BOUNDS.height));

		update();	// recalc
		render();	// draw
		
		//stage.addChild(new FPS(5, 5, 0xFFFFFF));
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
	}

	
	
	public function update():Void 
	{
		voronoi = new Voronoi(points, null, BOUNDS);
		regions = voronoi.regions();
		triangles = voronoi.delaunayTriangulation();
		hull = voronoi.hull();
		tree = voronoi.spanningTree();
	}
	
	public function render():Void {
		g.clear();
		drawTriangles();
		drawRegions();
		drawTree();
		drawHull();
		drawPoints();
		
		text.text = TEXT
			.replace("|POINTS|", bool2OnOff(showPoints))
			.replace("|REGIONS|", bool2OnOff(showRegions))
			.replace("|TRIANGLES|", bool2OnOff(showTriangles))
			.replace("|HULL|", bool2OnOff(showHull))
			.replace("|TREE|", bool2OnOff(showTree))
			.replace("|NPOINTS|", Std.string(nPoints));
			
	}
	
	inline function bool2OnOff(v:Bool):String 
	{
		return (v ? "[ON]" : "[OFF]");
	}
	
	
	
	public function drawPoints():Void 
	{
		if (!showPoints) return;
		g.lineStyle(THICKNESS, POINT_COLOR, ALPHA);
		for (p in points) {
			g.drawCircle(p.x, p.y, 2);
		}
	}
	
	public function drawRegions():Void 
	{
		if (!showRegions) return;
		g.lineStyle(THICKNESS, REGION_COLOR, ALPHA);
		
		for (region in regions) {
			g.moveTo(region[0].x, region[0].y);
			for (i in 1...region.length) {
				g.lineTo(region[i].x, region[i].y);
			}
		}
	}
	
	public function drawTriangles():Void 
	{
		if (!showTriangles) return;
		g.lineStyle(THICKNESS, TRIANGLE_COLOR, ALPHA);
		
		for (segment in triangles) {
			g.moveTo(segment.p0.x, segment.p0.y);
			g.lineTo(segment.p1.x, segment.p1.y);
		}
	}
	
	public function drawHull():Void 
	{
		if (!showHull) return;
		g.lineStyle(THICKNESS, HULL_COLOR, ALPHA);
		
		for (segment in hull) {
			g.moveTo(segment.p0.x, segment.p0.y);
			g.lineTo(segment.p1.x, segment.p1.y);
		}
	}
	
	public function drawTree():Void 
	{
		if (!showTree) return;
		g.lineStyle(THICKNESS, TREE_COLOR, ALPHA);
		
		for (segment in tree) {
			g.moveTo(segment.p0.x, segment.p0.y);
			g.lineTo(segment.p1.x, segment.p1.y);
		}
	}
	

	
	public function getTextField(text:String = "", x:Float, y:Float):TextField
	{
		var tf:TextField = new TextField();
		var fmt:TextFormat = new TextFormat(TEXT_FONT, null, TEXT_COLOR);
		fmt.align = TextFormatAlign.LEFT;
		fmt.size = TEXT_SIZE;
		tf.defaultTextFormat = fmt;
		tf.autoSize = TextFieldAutoSize.LEFT;
		tf.selectable = false;
		tf.x = x;
		tf.y = y;
		tf.filters = [TEXT_OUTLINE];
		tf.text = text;
		return tf;
	}

	public function onKeyDown(e:KeyboardEvent):Void 
	{
		switch (e.keyCode) 
		{
			// TOGGLE
			case Keyboard.NUMBER_1: showPoints = !showPoints;
			case Keyboard.NUMBER_2: showRegions = !showRegions;
			case Keyboard.NUMBER_3: showTriangles = !showTriangles;
			case Keyboard.NUMBER_4: showHull = !showHull;
			case Keyboard.NUMBER_5: showTree = !showTree;
			
			// POINTS
			case Keyboard.NUMPAD_ADD | 43 /* or plus next to enter */:
				points.push(new Point(Math.random() * BOUNDS.width, Math.random() * BOUNDS.height));
				nPoints = points.length;
				update();
			case Keyboard.NUMPAD_SUBTRACT | Keyboard.MINUS /* or minus next to RSHIFT */:
				if (nPoints > 3) {
					points.pop();
					nPoints = points.length;
					update();
				}
			case Keyboard.R:
				for (p in points) p.setTo(Math.random() * BOUNDS.width, Math.random() * BOUNDS.height);
				update();
		}
		trace(e.keyCode);
		render();
		
		if (e.keyCode == 27) {
		#if (flash || html5)
			System.exit(1);
		#else
			Sys.exit(1);
		#end
		}
	}
}