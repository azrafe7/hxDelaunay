package;


import com.nodename.delaunay.Voronoi;
import com.nodename.geom.LineSegment;
import com.nodename.geom.Point;
import com.nodename.geom.Rectangle;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.filters.GlowFilter;
import flash.system.System;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.ui.Keyboard;
import haxe.Timer;
import openfl.Assets;


using StringTools;

/**
 * hxDelaunay openFL demo.
 * 
 * @author azrafe7
 */
class Demo extends Sprite {

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
	private var CENTROID_COLOR:Int = 0x111111;
	private var MONALISA:String = "src/mona-lisa.png";
	
	private var THICKNESS:Float = 1.5;
	private var ALPHA:Float = 1.;
	private var FILL_ALPHA:Float = 1.;
	private var SAMPLE_FILL_ALPHA:Float = .8;
	private var CENTROID_ALPHA:Float = .5;

	private var TEXT_COLOR:Int = 0xFFFFFF;
	private var TEXT_FONT:String = "_typewriter";
	private var TEXT_SIZE:Float = 12;
	private var TEXT_OUTLINE:GlowFilter = new GlowFilter(0xFF000000, 1, 2, 2, 6);

	private var BOUNDS:Rectangle = new Rectangle(0, 0, 500, 500);
	
	private var voronoi:Voronoi;
	private var nPoints:Int = 25;
	private var points:Array<Point>;
	private var centroids:Array<Point>;
	private var directions:Array<Point>;
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
	private var monaListBMD:BitmapData;
	private var monaLisaBitmap:Bitmap;
	
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
	
	private var relax:Bool = false;
	private var animate:Bool = false;
	private var sampleImage:Bool = false;
	
	private var startTime:Float = 0;
	private var dt:Float = 0;
	
	private var text:TextField;
	
	private var TEXT:String =
		"         hxDelaunay \n" +
		"    (ported by azrafe7)\n\n" +
		"\n" +
		"          TOGGLE:\n\n" +
		" 1  points        : |POINTS|\n" +
		" 2  regions       : |REGIONS|\n" + 
		" 3  fill regions  : |FILL|\n" + 
		" 4  triangles     : |TRIANGLES|\n" +
		" 5  convex hull   : |HULL|\n" + 
		" 6  spanning tree : |TREE|\n" +
		" 7  onion         : |ONION|\n" +
		" 8  proximity map : |PROXIMITY|\n" +
		"\n" +
		" X  relax         : |RELAX|\n" +
		" A  animate       : |ANIMATE|\n" +
		" M  mona lisa     : |MONALISA|\n" +
		"\n\n" +
		"        POINTS: (|NPOINTS|)\n\n" +
		" +  add\n" +
		" -  remove\n" +
		"\n" +
		" R  randomize\n" +
		"\n\n" +
		"      click & drag to\n" +
		"     move region point" + 
		"\n";
	
		
	public function new () {
		super ();

		var sprite:Sprite = new Sprite();
		addChild(sprite);
		g = sprite.graphics;
		g.lineStyle(THICKNESS, TEXT_COLOR, ALPHA);

		addChild(text = getTextField(TEXT, BOUNDS.width + 10, 15));
		
		// mona lisa
		monaListBMD = Assets.getBitmapData(MONALISA);
		monaLisaBitmap = new Bitmap(monaListBMD);
		addChildAt(monaLisaBitmap, 0);
		
		// generate fill colors
		var MAX_COLORS = 10;
		fillColors = [for (i in 0...MAX_COLORS) colorLerp(MIN_FILL_COLOR, MAX_FILL_COLOR, i / MAX_COLORS)];
		centroids = new Array<Point>();
		directions = new Array<Point>();
		
		// first random set of points
		points = new Array<Point>();
		for (i in 0...nPoints) {
			points.push(new Point(Math.random() * BOUNDS.width, Math.random() * BOUNDS.height));
		}

		update();		// recalc
		render();		// draw
		updateText();	// info
		
		startTime = Timer.stamp();
		//stage.addChild(new FPS(5, 5, 0xFFFFFF));
		stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
	}

	public function update():Void 
	{
		if (voronoi != null) {
			voronoi.dispose();
			voronoi = null;
		}
		voronoi = new Voronoi(points, null, BOUNDS);
		regions = [for (p in points) voronoi.region(p)];
		sortedRegions = voronoi.regions();
		triangles = voronoi.delaunayTriangulation();
		hull = voronoi.hull();
		tree = voronoi.spanningTree();
		onion = calcOnion(voronoi);
		updateProximityMap();
	}
	
	public function updateText():Void 
	{
		text.text = TEXT
			.replace("|POINTS|", bool2OnOff(showPoints))
			.replace("|REGIONS|", bool2OnOff(showRegions))
			.replace("|FILL|", bool2OnOff(fillRegions))
			.replace("|TRIANGLES|", bool2OnOff(showTriangles))
			.replace("|HULL|", bool2OnOff(showHull))
			.replace("|TREE|", bool2OnOff(showTree))
			.replace("|ONION|", bool2OnOff(showOnion))
			.replace("|PROXIMITY|", bool2OnOff(showProximityMap))
			.replace("|NPOINTS|", Std.string(nPoints))
			.replace("|RELAX|", bool2OnOff(relax))
			.replace("|ANIMATE|", bool2OnOff(animate))
			.replace("|MONALISA|", bool2OnOff(sampleImage));
	}
	
	public function render():Void {
		g.clear();
		
		if (showRegions || fillRegions) drawRegions();
		monaLisaBitmap.visible = (sampleImage && (!fillRegions || SAMPLE_FILL_ALPHA < FILL_ALPHA));
		if (showProximityMap) {
			g.beginBitmapFill(proxymityMap);
			g.drawRect(0, 0, BOUNDS.width, BOUNDS.height);
			g.endFill();
		}
		if (showTriangles) drawTriangles();
		if (showTree) drawTree();
		if (showOnion) drawOnion();
		if (showHull) drawHull();
		if (showPoints) drawSiteCoords();
		if (selectedRegion != null) drawPoints(selectedRegion, SELECTED_COLOR);
		if (relax && showPoints) drawCentroids();
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
			var v:Voronoi = new Voronoi(points, null, BOUNDS);
			var peel = v.hullPointsInOrder();
			for (p in peel) points.remove(p);
			res.push(peel);
			v.dispose();
			v = null;
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

	public function drawCentroids():Void 
	{
		if (centroids.length < points.length) return;	// wait next frame
		for (i in 0...points.length) {
			var c = centroids[i];
			c.x = Math.round(c.x); c.y = Math.round(c.y);
			g.lineStyle(THICKNESS, CENTROID_COLOR, CENTROID_ALPHA);
			g.moveTo(c.x - 2, c.y); g.lineTo(c.x + 2, c.y);
			g.moveTo(c.x, c.y - 2); g.lineTo(c.x, c.y + 2);
		}
	}

	public function drawRegions():Void 
	{
		if (!sampleImage) {
			var fillIdx = -1;
			for (region in regions) {
				fillIdx = (fillIdx + 1) % fillColors.length;
				var fillColor = fillRegions ? fillColors[fillIdx] : null;
				
				drawPoints(region, fillRegions && !showRegions ? fillColors[fillIdx] : REGION_COLOR, fillColor);
			}
		} else {
			for (p in points) {
				var sampledColor = monaListBMD.getPixel(Std.int(p.x), Std.int(p.y));
				
				drawPoints(voronoi.region(p), fillRegions && showRegions ? REGION_COLOR : sampledColor, fillRegions ? sampledColor: null);
			}
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
		g.lineStyle(THICKNESS, color, sampleImage ? SAMPLE_FILL_ALPHA : ALPHA);
		if (fillColor != null) g.beginFill(fillColor, sampleImage ? SAMPLE_FILL_ALPHA : FILL_ALPHA);
		else g.beginFill(0, 0);
		
		for (p in points) {
			if (p == points[0]) g.moveTo(p.x, p.y);
			else g.lineTo(p.x, p.y);
		}
		
		g.endFill();
	}
	
	public function getCentroid(region:Array<Point>):Point 
	{
		var c = new Point();
		var len = region.length;
		for (i in 0...len) {
			var p0 = region[i];
			var p1 = region[(i + 1) % len];
			var m = p0.x * p1.y - p1.x * p0.y;
			c.x += (p0.x + p1.x) * m;
			c.y += (p0.y + p1.y) * m;
		}
		var area = getArea(region);
		c.x /= 6 * area;
		c.y /= 6 * area;
		return c;
	}
		
	public function getArea(region:Array<Point>):Float 
	{
		var area = 0.0;
		var len = region.length;
		for (i in 0...len) {
			var p0 = region[i];
			var p1 = region[(i + 1) % len];
			area += p0.x * p1.y - p1.x * p0.y;
		}
		return area = .5 * area;
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
			case Keyboard.X: 
				relax = !relax;
				animate = false;
			case Keyboard.A: 
				animate = !animate;
				relax = false;
			case Keyboard.M: sampleImage = !sampleImage; 
		}

		updateText();
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
		dt = Timer.stamp() - startTime;
		startTime = Timer.stamp();
		
		var mousePosChanged = !(mousePos.x == prevMousePos.x && mousePos.y == prevMousePos.y);
		
		if (relax) {
			for (i in 0...points.length) {
				var p = points[i];
				var r = voronoi.region(p);
				var c = getCentroid(r);
				(i == centroids.length) ? centroids.push(c) : centroids[i] = c;
				
				var distSquared = Point.distanceSquared(c, p);
				if (distSquared > 4.5) {	// slow down things a bit
					c.x -= p.x; c.y -= p.y;
					c.normalize(.75);
					p.x += c.x;	p.y += c.y;
				} else {
					p.x = c.x; p.y = c.y;
				}
			}
		}
		
		if (animate) {
			for (i in 0...points.length) {
				if (i == directions.length) {
					directions.push(new Point(30 * (Math.random() < .5 ? -1 : 1) * (Math.random() * .8 + .4), 30 * (Math.random() < .5 ? -1 : 1) * (Math.random() * .8 + .4)));
				}
				var p = points[i];
				var d = directions[i];
				var dx = d.x * dt;
				var dy = d.y * dt;
				if (p.x + dx < 0 || p.x + dx > BOUNDS.width) {
					d.x *= -1;
					dx *= -1;
				}
				if (p.y + dy < 0 || p.y + dy > BOUNDS.height) {
					d.y *= -1;
					dy *= -1;
				}
				p.x += dx;
				p.y += dy;
			}
		}
		
		if (relax || animate) {
			update();
			render();
		}
		
		if (isMouseDown && mousePos.x > 0 && mousePos.x < BOUNDS.width && mousePos.y > 0 && mousePos.y < BOUNDS.height) {
			var p = voronoi.nearestSitePoint(Std.int(mousePos.x), Std.int(mousePos.y));
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