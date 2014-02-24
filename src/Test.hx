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

	private var POINT_COLOR:Int = 0x00F000;
	private var REGION_COLOR:Int = 0x0020F0;
	private var MIN_FILL_COLOR:Int = 0x200040;
	private var MAX_FILL_COLOR:Int = 0x4000A0;
	private var FILL_ALPHA:Float = 1.;
	private var TRIANGLE_COLOR:Int = 0xFF0000;
	private var HULL_COLOR:Int = 0x3090F0;
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
	private var fillColors:Array<Int>;
	private var triangles:Array<LineSegment>;
	private var hull:Array<LineSegment>;
	private var tree:Array<LineSegment>;

	private var showPoints:Bool = true;
	private var showRegions:Bool = true;
	private var fillRegions:Bool = false;
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
		" 3  fill regions  : |FILL|\n" + 
		" 4  triangles     : |TRIANGLES|\n" +
		" 5  convex hull   : |HULL|\n" + 
		" 6  spanning tree : |TREE|\n" +
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
		
		// generate fill colors
		fillColors = [for (i in 0...10) colorLerp(MIN_FILL_COLOR, MAX_FILL_COLOR, i / 10)];
		
		// first random set of points
		points = new Array<Point>();
		for (i in 0...nPoints) points.push(new Point(Math.random() * BOUNDS.width, Math.random() * BOUNDS.height));

		update();	// recalc
		render();	// draw
		
		//stage.addChild(new FPS(5, 5, 0xFFFFFF));
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
	}

	
	
	public function update():Void 
	{
		voronoi = new Voronoi(points, null, BOUNDS);
		regions = [for (p in points) voronoi.region(p)];
		triangles = voronoi.delaunayTriangulation();
		hull = voronoi.hull();
		tree = voronoi.spanningTree();
	}
	
	public function render():Void {
		g.clear();
		drawRegions();
		drawTriangles();
		drawTree();
		drawHull();
		drawPoints();
		
		text.text = TEXT
			.replace("|POINTS|", bool2OnOff(showPoints))
			.replace("|REGIONS|", bool2OnOff(showRegions))
			.replace("|FILL|", bool2OnOff(fillRegions))
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
		
		var fillIdx = -1;
		for (region in regions) {
			if (fillRegions) {
				fillIdx = (fillIdx + 1) % fillColors.length;
				g.beginFill(fillColors[fillIdx], FILL_ALPHA);
			}
			
			g.moveTo(region[0].x, region[0].y);
			for (i in 1...region.length) {
				g.lineTo(region[i].x, region[i].y);
			}
			g.endFill();
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
			case Keyboard.NUMBER_3: fillRegions = !fillRegions;
			case Keyboard.NUMBER_4: showTriangles = !showTriangles;
			case Keyboard.NUMBER_5: showHull = !showHull;
			case Keyboard.NUMBER_6: showTree = !showTree;
			
			// POINTS
			case Keyboard.NUMPAD_ADD, 43 /* or plus next to enter */:
				points.push(new Point(Math.random() * BOUNDS.width, Math.random() * BOUNDS.height));
				nPoints = points.length;
				update();
			case Keyboard.NUMPAD_SUBTRACT, Keyboard.MINUS /* or minus next to RSHIFT */:
				if (nPoints > 3) {
					points.pop();
					nPoints = points.length;
					update();
				}
			case Keyboard.R:
				for (p in points) p.setTo(Math.random() * BOUNDS.width, Math.random() * BOUNDS.height);
				update();
		}

		render();
		
		if (e.keyCode == 27) {
		#if (flash || html5)
			System.exit(1);
		#else
			Sys.exit(1);
		#end
		}
	}
	
	public function colorLerp(fromColor:Int, toColor:Int, t:Float = 1):Int
	{
		if (t <= 0) { return fromColor; }
		if (t >= 1) { return toColor; }
		var r:Int = fromColor >> 16 & 0xFF,
			g:Int = fromColor >> 8 & 0xFF,
			b:Int = fromColor & 0xFF,
			dR:Int = (toColor >> 16 & 0xFF) - r,
			dG:Int = (toColor >> 8 & 0xFF) - g,
			dB:Int = (toColor & 0xFF) - b;
		r += Std.int(dR * t);
		g += Std.int(dG * t);
		b += Std.int(dB * t);
		return r << 16 | g << 8 | b;
	}
}