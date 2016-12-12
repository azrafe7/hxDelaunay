hxDelaunay
==========

Port to Haxe 3 of [sledorze/hxDelaunay](https://github.com/sledorze/hxDelaunay) (itself a port of the excellent [nodename/as3delaunay](https://github.com/nodename/as3delaunay)).

[![click for flash demo](screenshot.png)](https://dl.dropboxusercontent.com/u/32864004/dev/FPDemo/hxDelaunayTest.swf)
(click the image above to try the [flash demo](https://dl.dropboxusercontent.com/u/32864004/dev/FPDemo/hxDelaunayTest.swf) - if you have problems and you're on Chrome, please try [disabling the Flash Pepper plugin](http://nusofthq.com/blog/how-to-disable-the-chrome-pepper-flash-plugin/))

No external dependencies (demo still needs openfl). Tested on flash/js/cpp/neko.

### Features: ###

 - [Voronoi diagram](http://en.wikipedia.org/wiki/Voronoi)
 - [Delaunay triangulation](http://en.wikipedia.org/wiki/Delaunay_triangulation)
 - [Convex hull](http://en.wikipedia.org/wiki/Convex_hull)
 - [Minimum spanning tree](http://en.wikipedia.org/wiki/Euclidean_minimum_spanning_tree)
 - [Onion](http://cgm.cs.mcgill.ca/~orm/ontri.html)

See original authors links for details and licensing (MIT).


### Update:

- Delaunay triangulation visualisation [see js example](https://github.com/MatthijsKamstra/hxDelaunay/blob/master/src/DemoJs.hx)


# haxelib local use

Currently there is no haxelib, but you can use this git repos as a development directory:

```
haxelib dev hxdelaunay path/to/folder
```

or use git directly

```
haxelib git hxdelaunay https://github.com/MatthijsKamstra/hxDelaunay.git
```

don't forget to add it to your build file

```
-lib hxdelaunay
```

or for openfl

```
<haxelib name="hxdelaunay" />
```


Check out the [openfl example](https://github.com/MatthijsKamstra/hxDelaunay/blob/master/src/Demo.hx) folder for more information.


Or a simpler [js code example](https://github.com/MatthijsKamstra/hxDelaunay/blob/master/src/DemoJs.hx)

See it in action [JavaScript example](http://htmlpreview.github.io/?https://github.com/MatthijsKamstra/hxDelaunay/blob/master/bin/js/index.html)

**Enjoy!**

