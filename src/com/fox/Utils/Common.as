import flash.geom.Point;
class com.fox.Utils.Common {

	public function Common() {
	}

	public static function getOnScreen( mc:MovieClip) : Point {

		var point:Point = new Point(mc._x, mc._y);
		if ( mc._x < 0 ) point.x = 0;
		else if ( mc._x + mc._width > Stage.visibleRect.width ) point.x = Stage.visibleRect.width - mc._width;
		if ( mc._y < 0 ) point.y = 0;
		else if ( mc._y + mc._height > Stage.visibleRect.height ) point.y = Stage.visibleRect.height - mc._height;
		return point;
	}
}