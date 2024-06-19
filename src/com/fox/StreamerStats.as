import com.GameInterface.ClientServerPerfTracker;
import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.GameInterface.Inventory;
import com.GameInterface.UtilsBase;
import com.Utils.Archive;
import com.Utils.Draw;
import com.Utils.GlobalSignal;
import com.fox.Utils.Common;
import flash.filters.DropShadowFilter;
import flash.geom.Point;	
import mx.utils.Delegate;

class com.fox.StreamerStats
{
	private var m_swfRoot:MovieClip;
	private var m_Box:MovieClip;
	private var m_Character:Character
	private var m_pos:Point;
	private var clipSize:Number;
	private var mode:Boolean;
	private var updateInterval:Number;
	private var cachedPlayed:Number;
	private var displayStringDval:DistributedValue;
	private var displayStringTemplate:String;
	private var redraw:Boolean;
	private var FPS:Number = 0;
	private var LATENCY:Number = 0;

	public static function main(swfRoot:MovieClip):Void
	{
		var s_app:StreamerStats = new StreamerStats(swfRoot);
		swfRoot.onLoad = function() {s_app.Load()};
		swfRoot.onUnload = function() {s_app.Unload()};
		swfRoot.OnModuleActivated = function(config) {s_app.Activate(config)};
		swfRoot.OnModuleDeactivated = function() {return s_app.Deactivate()};
	}

	public function StreamerStats(root)
	{
		m_swfRoot = root;
		displayStringDval = DistributedValue.Create("StreamerStats_DisplayString");
		displayStringTemplate = displayStringDval.GetValue();
		displayStringTemplate = displayStringTemplate.split("\\n").join("\n");
	}

	public function Load()
	{
		m_Character = Character.GetClientCharacter();
		cachedPlayed = undefined;
		GlobalSignal.SignalSetGUIEditMode.Connect(GuiEdit, this);
		displayStringDval.SignalChanged.Connect(UpdateDisplayString, this);
		ClientServerPerfTracker.SignalClientFramerateUpdated.Connect( SlotClientFramerateUpdated, this );
		ClientServerPerfTracker.SignalLatencyUpdated.Connect( SlotClientLatencyUpdated, this );
	}
	
	public function UpdateDisplayString(dv:DistributedValue)
	{
		displayStringTemplate = dv.GetValue();
		displayStringTemplate = displayStringTemplate.split("\\n").join("\n");
		redraw = true;
	}
	
	public function Unload()
	{
		GlobalSignal.SignalSetGUIEditMode.Disconnect(GuiEdit, this);
		clearInterval(updateInterval);
		displayStringDval.SignalChanged.Disconnect(UpdateDisplayString, this);
		ClientServerPerfTracker.SignalClientFramerateUpdated.Disconnect( SlotClientFramerateUpdated, this );
		ClientServerPerfTracker.SignalLatencyUpdated.Disconnect( SlotClientLatencyUpdated, this );
	}
	
	public function SlotClientFramerateUpdated(fps:Number):Void 
	{
		FPS = fps;
	}
	
	public function SlotClientLatencyUpdated(latency:Number):Void 
	{
		LATENCY = latency;
	}

	public function Activate(config:Archive):Void
	{
		cachedPlayed = m_Character.GetStat(58);
		if (!m_Box)
		{
			m_pos = Point(config.FindEntry("position", new Point(650, 0)));
			clipSize = config.FindEntry("clipSize", 100);
			mode = config.FindEntry("mode", true);
			CreateTextBox();
		}
		clearInterval(updateInterval);
		updateInterval = setInterval(Delegate.create(this, UpdatePlayed), 500);
	}

	public function Deactivate()
	{
		var config:Archive = new Archive();
		config.AddEntry("position", m_pos);
		config.AddEntry("clipSize", clipSize);
		config.AddEntry("mode", mode);
		return config
	}

	private function onMouseWheel(delta:Number)
	{
		if ( Mouse.getTopMostEntity() == m_Box)
		{
			clipSize = Math.min(600, Math.max(50, clipSize + 5 * delta));
			m_Box._xscale = m_Box._yscale = clipSize
			SetOnScreen();
		}
	}

	private function DrawBackground()
	{
		m_Box.Background._width = m_Box.text._width + 10;
		m_Box.Background._height = m_Box.text._height + 10;
	}

	private function GuiEdit(state:Boolean)
	{
		if (state)
		{
			m_Box.onPress = Delegate.create(this,function ():Void
			{
				this.m_Box.startDrag();
			});
			m_Box.onRelease = m_Box.onReleaseOutside = Delegate.create(this,function ():Void
			{
				this.m_Box.stopDrag();
			});
			m_Box.onPressAux = Delegate.create(this, function(){
				this.mode = !this.mode;
				if ( this.mode ) this.m_Box.Background._alpha = 30;
				else this.m_Box.Background._alpha = 0;
			});
			Mouse.addListener(this);
		}
		else
		{
			m_Box.stopDrag();
			m_Box.onPressAux = m_Box.onPress = m_Box.onRelease = m_Box.onReleaseOutside = undefined;
			SetOnScreen();
			Mouse.removeListener(this);
		}
	}

	private function CalculateTimeString(totalSeconds, mode):String
	{
		var totalMinutes = totalSeconds / 60;
		var hours = totalMinutes / 60;
		var hoursString = String(Math.floor(hours));
		if (hoursString.length == 1) { hoursString = "0" + hoursString; }
		var seconds = totalSeconds % 60;
		var secondsString = String(Math.floor(seconds));
		if (secondsString.length == 1) { secondsString = "0" + secondsString; }
		var minutes = totalMinutes % 60;
		var minutesString = String(Math.floor(minutes));
		if (minutesString.length == 1) { minutesString = "0" + minutesString; }
		if (mode == 0) return hoursString + ":" + minutesString + ":" + secondsString;
		else if ( mode == 1) return hoursString + ":" + minutesString;
		else if ( mode == 2) return hoursString;
		else if ( mode == 3)
		{
			var days = hours / 24;
			if (days > 1)
			{
				hours = String(Math.floor(hours % 24));
				if (hours.length == 1) { hours = "0" + hours; }
				return Math.floor(days) + "d " + hours + "h";
			}
			else return hoursString + "h " + minutesString + "m";
		}
	}

	private function SetOnScreen():Void
	{
		m_pos = Common.getOnScreen(m_Box);
		m_Box._x = m_pos.x;
		m_Box._y = m_pos.y;
	}

	private function UpdatePlayed(skipAdd)
	{
		if (!skipAdd) cachedPlayed += 0.5;
		// played only updates every few seconds
		if ( cachedPlayed % 2 == 0 || !cachedPlayed)
		{
			cachedPlayed = m_Character.GetStat(58);
		}
		m_Box.text.text = "";
		if (!displayStringTemplate) return;
		
		var displayString:String = displayStringTemplate;
		
		var index = displayString.toLowerCase().indexOf("%first%")
		if ( index >= 0)
		{
			displayString = displayString.slice(0, index) + m_Character.GetFirstName() + displayString.slice(index + 7);
		}
		
		index = displayString.toLowerCase().indexOf("%last%")
		if ( index >= 0)
		{
			displayString = displayString.slice(0, index) + m_Character.GetLastName() + displayString.slice(index + 6);
		}
		
		index = displayString.toLowerCase().indexOf("%name%")
		if ( index >= 0)
		{
			displayString = displayString.slice(0, index) + m_Character.GetName() + displayString.slice(index + 6);
		}
		
		index = displayString.toLowerCase().indexOf("%ip%")
		if ( index >= 0)
		{
			displayString = displayString.slice(0, index) + m_Character.GetStat(2000607) + displayString.slice(index + 4);
		}
		
		index = displayString.toLowerCase().indexOf("%maxip%")
		if ( index >= 0)
		{
			var IP:Number = m_Character.GetStat(2000607);
			var maxIP:Number = m_Character.GetStat(2000767);
			var highest = Math.max(IP, maxIP);
			displayString = displayString.slice(0, index) + highest + displayString.slice(index + 7);
		}
		
		index = displayString.toLowerCase().indexOf("%played0%")
		if ( index >= 0)
		{
			displayString = displayString.slice(0, index) + CalculateTimeString(cachedPlayed, 0) + displayString.slice(index + 9);
		}
		
		index = displayString.toLowerCase().indexOf("%played1%")
		if ( index >= 0)
		{
			displayString = displayString.slice(0, index) + CalculateTimeString(cachedPlayed, 1) + displayString.slice(index + 9);
		}
		
		index = displayString.toLowerCase().indexOf("%played2%")
		if ( index >= 0)
		{
			displayString = displayString.slice(0, index) + CalculateTimeString(cachedPlayed, 2) + displayString.slice(index + 9);
		}
		
		index = displayString.toLowerCase().indexOf("%played3%")
		if ( index >= 0)
		{
			displayString = displayString.slice(0, index) + CalculateTimeString(cachedPlayed, 3) + displayString.slice(index + 9);
		}
		
		index = displayString.toLowerCase().indexOf("%fps0%")
		if ( index >= 0)
		{
			displayString = displayString.slice(0, index) + com.Utils.Format.Printf( "%.2f", FPS ) + displayString.slice(index + 6);
		}
		
		index = displayString.toLowerCase().indexOf("%fps1%")
		if ( index >= 0)
		{
			displayString = displayString.slice(0, index) + com.Utils.Format.Printf( "%.0f", FPS ) + displayString.slice(index + 6);
		}
		
		index = displayString.toLowerCase().indexOf("%latency0%")
		if ( index >= 0)
		{
			displayString = displayString.slice(0, index) + Math.floor(LATENCY*1000) + displayString.slice(index + 10);
		}
		
		index = displayString.toLowerCase().indexOf("%latency1%")
		if ( index >= 0)
		{
			displayString = displayString.slice(0, index) + com.Utils.Format.Printf( "%.3f", LATENCY ) + displayString.slice(index + 10);
		}
		
		index = displayString.toLowerCase().indexOf("%latency2%")
		if ( index >= 0)
		{
			displayString = displayString.slice(0, index) + com.Utils.Format.Printf( "%.2f", LATENCY ) + displayString.slice(index + 10);
		}
		
		var pos = m_Character.GetPosition();
		index = displayString.toLowerCase().indexOf("%x%")
		if ( index >= 0)
		{
			displayString = displayString.slice(0, index) + Math.floor(pos.x) + displayString.slice(index + 3);
		}
		
		index = displayString.toLowerCase().indexOf("%y%")
		if ( index >= 0)
		{
			displayString = displayString.slice(0, index) + Math.floor(pos.y) + displayString.slice(index + 3);
		}
		
		index = displayString.toLowerCase().indexOf("%z%")
		if ( index >= 0)
		{
			displayString = displayString.slice(0, index) + Math.floor(pos.z) + displayString.slice(index + 3);
		}
		
		m_Box.text.text = displayString;
		if ( redraw )
		{
			DrawBackground();
		}
	}
	
	private function CreateTextBox():Void
	{
		m_Box = m_swfRoot.createEmptyMovieClip("m_Box", m_swfRoot.getNextHighestDepth());
		var Background:MovieClip = m_Box.createEmptyMovieClip("Background", m_Box.getNextHighestDepth());
		Draw.DrawRectangle(Background, 0, 0, 100, 100, 0x000000, 100,[4,4,4,4]);
		if (mode) Background._alpha = 30;
		else Background._alpha = 0;
		var textFormat = new TextFormat("src.assets.fonts.FuturaMD_BT.ttf", 14, 0xFFFFFF,false);
		var textField:TextField = m_Box.createTextField("text", m_Box.getNextHighestDepth(), 5, 5, 0, 0);
		textField.filters = [new DropShadowFilter(20, 45, 0x000000, 1, 4, 4, 1, 2, false, false, false)];
		textField.autoSize = true;
		textField.setTextFormat(textFormat);
		textField.setNewTextFormat(textFormat);
		textField.multiline = true;
		UpdatePlayed(true);
		DrawBackground();

		m_Box._x = m_pos.x;
		m_Box._y = m_pos.y;
		m_Box._xscale = m_Box._yscale = clipSize;
		SetOnScreen();
		GuiEdit(false);
	}
}