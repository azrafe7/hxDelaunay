package com.nodename.delaunay;

import com.nodename.geom.Point;

using com.nodename.delaunay.ArrayHelper;


class Triangle {
	public var sites(get, null) : Array<Site>;
	inline private function get_sites():Array<Site> {
		return sites;
	}
	
	public var points(get, null) : Array<Point>;
	inline private function get_points():Array<Point> {
		return points;
	}
	
	public function new(a:Site, b:Site, c:Site) {
		sites = [a, b, c];
		points = [a.coord, b.coord, c.coord];
	}
	
	public function dispose():Void {
		sites.clear();
		sites = null;
		points.clear();
		points = null;
	}

}
