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
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
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
	private var REGION_COLOR:Int = 0x4000F0;
	private var MIN_FILL_COLOR:Int = 0x200040;
	private var MAX_FILL_COLOR:Int = 0x4000A0;
	private var TRIANGLE_COLOR:Int = 0xF00000;
	private var HULL_COLOR:Int = 0x30F090;
	private var TREE_COLOR:Int = 0xF0C020;
	private var ONION_COLOR:Int = 0x10A0FF;
	private var SELECTED_COLOR:Int = 0x8020F0;
	
	private var THICKNESS:Float = 1.5;
	private var ALPHA:Float = 1.;
	private var FILL_ALPHA:Float = 1.;

	private var TEXT_COLOR:Int = 0xFFFFFFFF;
	private var TEXT_FONT:String = "_typewriter";
	private var TEXT_SIZE:Float = 12;
	private var TEXT_OUTLINE:GlowFilter = new GlowFilter(0xFF000000, 1, 2, 2, 6);

	private var BOUNDS:Rectangle = new Rectangle(0, 0, 500, 500);
	
	private var voronoi:Voronoi;
	private var nPoints:Int = 25;
	private var points:Array<Point>;
	private var regions:Array<Array<Point>>;
	private var sortedRegions:Array<Array<Point>>;
	private var fillColors:Array<Int>;
	private var triangles:Array<LineSegment>;
	private var hull:Array<LineSegment>;
	private var tree:Array<LineSegment>;
	private var onion:Array<Array<Point>>;
	private var proxymitySprite:Sprite;
	private var proxymityMap:BitmapData;
	private var selectedRegion:Array<Point>;
	
	private var isMouseDown:Bool = false;
	private var prevMousePos:Point = new Point();
	private var mousePos:Point = new Point();

	private var showPoints:Bool = true;
	private var showRegions:Bool = true;
	private var fillRegions:Bool = false;
	private var showTriangles:Bool = false;
	private var showHull:Bool = false;
	private var showTree:Bool = false;
	private var showOnion:Bool = false;
	private var showProximityMap:Bool = false;
	
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
		" 7  onion         : |ONION|\n" +
		" 8  proximityMap  : |PROXIMITY|\n" +
		"\n\n" +
		"        POINTS: (|NPOINTS|)\n\n" +
		" +  add\n" +
		" -  remove\n\n" +
		" R  randomize\n" +
		"\n\n" +
		"      click & drag to\n" +
		"     move region point";
	
		
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
		stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
	}

	
	
	public function update():Void 
	{
		voronoi = new Voronoi(points, null, BOUNDS);
		regions = [for (p in points) voronoi.region(p)];
		sortedRegions = voronoi.regions();
		triangles = voronoi.delaunayTriangulation();
		hull = voronoi.hull();
		tree = voronoi.spanningTree();
		onion = calcOnion(voronoi);
		updateProximityMap();
	}
	
	public function render():Void {
		g.clear();
		
		if (showRegions) drawRegions();
		if (showProximityMap) {
			g.beginBitmapFill(proxymityMap);
			g.drawRect(0, 0, BOUNDS.width, BOUNDS.height);
			g.endFill();
		}
		if (showTriangles) drawTriangles();
		if (showOnion) drawOnion();
		if (showTree) drawTree();
		if (showHull) drawHull();
		if (showPoints) drawSiteCoords();
		if (selectedRegion != null) drawPoints(selectedRegion, SELECTED_COLOR);
		
		text.text = TEXT
			.replace("|POINTS|", bool2OnOff(showPoints))
			.replace("|REGIONS|", bool2OnOff(showRegions))
			.replace("|FILL|", bool2OnOff(fillRegions))
			.replace("|TRIANGLES|", bool2OnOff(showTriangles))
			.replace("|HULL|", bool2OnOff(showHull))
			.replace("|TREE|", bool2OnOff(showTree))
			.replace("|ONION|", bool2OnOff(showOnion))
			.replace("|PROXIMITY|", bool2OnOff(showProximityMap))
			.replace("|NPOINTS|", Std.string(nPoints));
			
	}
	
	inline function bool2OnOff(v:Bool):String 
	{
		return (v ? "[ON]" : "[OFF]");
	}
	
	public function updateProximityMap():Void {
		if (proxymityMap == null) {
			proxymityMap = new BitmapData(Std.int(BOUNDS.width), Std.int(BOUNDS.height), false);
			proxymitySprite = new Sprite();
		} 
		var graphics = proxymitySprite.graphics;
		proxymityMap.fillRect(proxymityMap.rect, 0xFFFFFFFF);
		graphics.clear();
		
		for (i in 0...sortedRegions.length) {
			graphics.lineStyle(1, i, 1);	// no borders
			graphics.beginFill(i);
			var points = sortedRegions[i];
			for (p in points) {
				if (p == points[0]) graphics.moveTo(p.x, p.y);
				else graphics.lineTo(p.x, p.y);
			}
			graphics.endFill();
		}
		proxymityMap.draw(proxymitySprite);
	}
	
	public function calcOnion(voronoi:Voronoi):Array<Array<Point>> 
	{
		var res = new Array<Array<Point>>();
		var points = voronoi.siteCoords();
		
		while (points.length > 2) {
			var v:Voronoi = new Voronoi(points, null, voronoi.getPlotBounds());
			var peel = v.hullPointsInOrder();
			for (p in peel) points.remove(p);
			res.push(peel);
			v.dispose();
		}
		if (points.length > 0) res.push(points);
		
		return res;
	}
	
	
	
	public function drawSiteCoords():Void 
	{
		g.lineStyle(THICKNESS, POINT_COLOR, ALPHA);
		for (p in points) {
			g.drawCircle(p.x, p.y, 2);
		}
	}

	public function drawRegions():Void 
	{
		var fillIdx = -1;
		for (region in regions) {
			if (fillRegions) fillIdx = (fillIdx + 1) % fillColors.length;
			
			drawPoints(region, REGION_COLOR, fillRegions ? fillColors[fillIdx] : null);
		}
	}
	
	inline public function drawTriangles():Void 
	{
		drawSegments(triangles, TRIANGLE_COLOR);
	}
	
	inline public function drawHull():Void 
	{
		drawSegments(hull, HULL_COLOR);
	}
	
	inline public function drawTree():Void 
	{
		drawSegments(tree, TREE_COLOR);
	}

	public function drawOnion():Void 
	{
		for (peel in onion) {
			drawPoints(peel, ONION_COLOR);
		}
	}
	

	
	// generic draw function for segments
	public function drawSegments(segments:Array<LineSegment>, color:Int, ?fillColor:Int = null) {
		g.lineStyle(THICKNESS, color, ALPHA);
		if (fillColor != null) g.beginFill(fillColor, FILL_ALPHA);
		else g.beginFill(0, 0);
		
		for (segment in segments) {
			g.moveTo(segment.p0.x, segment.p0.y);
			g.lineTo(segment.p1.x, segment.p1.y);
		}
		
		g.endFill();
	}
	
	
	// generic draw function for points
	public function drawPoints(points:Array<Point>, color:Int, ?fillColor:Int = null) {
		g.lineStyle(THICKNESS, color, ALPHA);
		if (fillColor != null) g.beginFill(fillColor, FILL_ALPHA);
		else g.beginFill(0, 0);
		
		for (p in points) {
			if (p == points[0]) g.moveTo(p.x, p.y);
			else g.lineTo(p.x, p.y);
		}
		
		g.endFill();
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
			case Keyboard.NUMBER_7: showOnion = !showOnion;
			case Keyboard.NUMBER_8: showProximityMap = !showProximityMap;
			
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
	
	public function onMouseDown(e:MouseEvent):Void 
	{
		isMouseDown = true;
	}
	
	public function onMouseUp(e:MouseEvent):Void 
	{
		isMouseDown = false;
		selectedRegion = null;
		render();
	}
	
	public function onMouseMove(e:MouseEvent):Void 
	{
		mousePos.setTo(e.stageX, e.stageY);
	}
	
	public function onEnterFrame(e:Event):Void {
		var mousePosChanged = !(mousePos.x == prevMousePos.x && mousePos.y == prevMousePos.y);
		
		if (isMouseDown && mousePos.x > 0 && mousePos.x < BOUNDS.width && mousePos.y > 0 && mousePos.y < BOUNDS.height) {
			var p = voronoi.nearestSitePoint(proxymityMap, Std.int(mousePos.x), Std.int(mousePos.y));
			if (p != null) {
				points[points.indexOf(p)].setTo(mousePos.x, mousePos.y);
				if (mousePosChanged) update();
				selectedRegion = voronoi.region(p);
				render();
			}
			prevMousePos.setTo(mousePos.x, mousePos.y);
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