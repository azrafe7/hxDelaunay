package com.nodename.delaunay;

using com.nodename.delaunay.ArrayHelper;


class Triangle {
	public var sites(get, null) : Array<Site>;
	inline private function get_sites():Array<Site> {
		return sites;
	}
	
	public function new(a:Site, b:Site, c:Site) {
		sites = [a, b, c];
	}
	
	public function dispose():Void {
		sites.clear();
		sites = null;
	}

}
