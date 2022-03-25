package;

#if desktop
import Discord.DiscordClient;
#end
import Achievements;
import WeekData;
import editors.MasterEditorMenu;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import lime.utils.Assets;

using StringTools;

class CharacterSelect extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.5.1'; // This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var scoreText:FlxText;
	var intendedScore:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;

	var optionShit:Array<String> = ['dededebutton', 'metaknightbutton', 'comingsoonbutton'];

	var bg:FlxSprite;
	var menuTop:FlxSprite;
	var menuBottom:FlxSprite;
	var scoreBubble:FlxSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;
	var colorTween:FlxTween;
	var menuItem:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;
	var txtTracks:FlxText;
	var txtTracklist1:FlxText;
	var txtTracklist2:FlxText;
	var txtTracklist3:FlxText;

	private var curColor:FlxColor = 0xFFFFFFFF;

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		WeekData.setDirectoryFromWeek();
		WeekData.reloadWeekFiles(true);

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement);
		FlxCamera.defaultCameras = [camGame];

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);
		bg.screenCenter();

		menuTop = new FlxSprite(-80, -150).loadGraphic(Paths.image('storycharacters/Menu+'));
		menuTop.setGraphicSize(Std.int(menuTop.width * 0.8));
		menuTop.screenCenter(X);
		menuTop.antialiasing = ClientPrefs.globalAntialiasing;
		menuTop.color = curColor;
		add(menuTop);

		menuBottom = new FlxSprite(-80, 450).loadGraphic(Paths.image('storycharacters/Menu-'));
		menuBottom.setGraphicSize(Std.int(menuBottom.width * 0.8));
		menuBottom.screenCenter(X);
		menuBottom.antialiasing = ClientPrefs.globalAntialiasing;
		menuBottom.color = curColor;
		add(menuBottom);

		scoreBubble = new FlxSprite(0, 0).loadGraphic(Paths.image('storycharacters/Score Bubble'));
		scoreBubble.setGraphicSize(Std.int(scoreBubble.width * 0.7));
		scoreBubble.screenCenter();
		scoreBubble.x -= 400;
		scoreBubble.y += 75;
		scoreBubble.antialiasing = ClientPrefs.globalAntialiasing;
		scoreBubble.alpha = 0;
		add(scoreBubble);

		txtTracks = new FlxText(scoreBubble.x + 140, scoreBubble.y - 200, 0, "TRACKS:", 48);
		txtTracks.setFormat(Paths.font("Delfino.ttf"), 48, 0xFF666666, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(txtTracks);

		var oppText:FlxText = new FlxText(scoreBubble.x + 60, scoreBubble.y + 350, 0, "CHOOSE YOUR OPPONENT:", 48);
		oppText.setFormat(Paths.font("Delfino.ttf"), 48, 0xFF666666, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.GRAY);
		add(oppText);

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		leftArrow = new FlxSprite(800, 575);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		leftArrow.antialiasing = ClientPrefs.globalAntialiasing;
		add(leftArrow);

		rightArrow = new FlxSprite(leftArrow.x + 300, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		rightArrow.antialiasing = ClientPrefs.globalAntialiasing;
		add(rightArrow);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		// magenta.scrollFactor.set();

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;
		/*if(optionShit.length > 6) {
			scale = 6 / optionShit.length;
		}*/

		for (i in 0...optionShit.length)
		{
			menuItem = new FlxSprite(0, 0);
			menuItem.scale.x = scale / 1.6;
			menuItem.scale.y = scale / 1.6;
			menuItem.frames = Paths.getSparrowAtlas('storycharacters/' + optionShit[i]);
			menuItem.animation.addByPrefix('confirmed', optionShit[i] + " confirm", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " select", 24);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " static", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter();
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if (optionShit.length < 6)
				scr = 0;
			if (menuItem.ID == 0)
			{
				menuItem.x = 840;
				menuItem.y += 150;
				txtTracklist1 = new FlxText(txtTracks.x - 50, txtTracks.y + 60, 0, "DeDeDe: Clobberin", 32);
				txtTracklist1.setFormat(Paths.font("Delfino.ttf"), 32, 0xFFCCCCCC, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				add(txtTracklist1);
			}
			if (menuItem.ID == 1)
			{
				menuItem.x = 850;
				menuItem.y += 150;
				txtTracklist2 = new FlxText(txtTracklist1.x, txtTracklist1.y + 60, 0, "Meta-Knight: Star Warrior", 32);
				txtTracklist2.setFormat(Paths.font("Delfino.ttf"), 32, 0xFFCCCCCC, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				add(txtTracklist2);
			}
			if (menuItem.ID == 2)
			{
				menuItem.x = 850;
				menuItem.y += 150;
				txtTracklist3 = new FlxText(txtTracklist1.x, txtTracklist2.y + 60, 0, "COMING SOON", 32);
				txtTracklist3.setFormat(Paths.font("Delfino.ttf"), 32, 0xFFCCCCCC, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				add(txtTracklist3);
			}

			menuItem.scrollFactor.set(0, scr);
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			// menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
			menuItem.updateHitbox();
		}

		// add(versionShit);

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		super.create();
	}

	var selectedSomethin:Bool = false;
	var lerpScore:Int = 0;
	var curDifficulty:Int = CoolUtil.difficulties.length;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!selectedSomethin)
		{
			if (controls.UI_LEFT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_RIGHT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}

			if (controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'comingsoonbutton')
				{
					FlxG.camera.shake(0.025);
				}
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));
					menuItems.forEach(function(spr:FlxSprite)
					{
						if (curSelected != spr.ID)
						{
							FlxTween.tween(spr, {alpha: 0}, 0.4, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							spr.animation.play('confirmed');
							FlxFlicker.flicker(spr, 0.5, 0.06, false, false, function(flick:FlxFlicker)
							{
								var daChoice:String = optionShit[curSelected];
								switch (daChoice)
								{
									case 'dededebutton':
										var songArray:Array<String> = [];
										var leWeek:Array<Dynamic> = WeekData.weeksLoaded.get(WeekData.weeksList[0]).songs;
										var curDifficulty:Int = CoolUtil.difficulties.length;
										for (i in 0...leWeek.length)
										{
											songArray.push(leWeek[i][0]);
										}
										PlayState.storyPlaylist = songArray;
										PlayState.isStoryMode = true;

										var diffic = CoolUtil.getDifficultyFilePath(curDifficulty);
										if (diffic == null)
											diffic = 'Hard';

										PlayState.storyDifficulty = 2;

										PlayState.SONG = Song.loadFromJson('Clobberin' + '-Hard', 'Clobberin');
										PlayState.campaignScore = 0;
										PlayState.campaignMisses = 0;
										{
											LoadingState.loadAndSwitchState(new PlayState(), true);
											FreeplayState.destroyFreeplayVocals();
										};
									case 'metaknightbutton':
										var songArray:Array<String> = [];
										var leWeek:Array<Dynamic> = WeekData.weeksLoaded.get(WeekData.weeksList[0]).songs;
										var curDifficulty:Int = CoolUtil.difficulties.length;
										for (i in 0...leWeek.length)
										{
											songArray.push(leWeek[i][0]);
										}

										// Nevermind that's stupid lmao
										PlayState.storyPlaylist = songArray;
										PlayState.isStoryMode = true;

										var diffic = CoolUtil.getDifficultyFilePath(curDifficulty);
										if (diffic == null)
											diffic = 'Hard';

										PlayState.storyDifficulty = 2;

										PlayState.SONG = Song.loadFromJson('Star-Warrior' + '-Hard', 'Star-Warrior');
										PlayState.campaignScore = 0;
										PlayState.campaignMisses = 0;
										{
											LoadingState.loadAndSwitchState(new PlayState(), true);
											FreeplayState.destroyFreeplayVocals();
										};
								}
							});
						}
					});
				}
			}
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		if (colorTween != null)
		{
			colorTween.cancel();
		}
		colorTween = FlxTween.color(bg, 1, bg.color, curColor, {
			onComplete: function(twn:FlxTween)
			{
				colorTween = null;
			}
		});
		if (colorTween != null)
		{
			colorTween.cancel();
		}
		colorTween = FlxTween.color(menuTop, 1, menuTop.color, curColor, {
			onComplete: function(twn:FlxTween)
			{
				colorTween = null;
			}
		});
		if (colorTween != null)
		{
			colorTween.cancel();
		}
		colorTween = FlxTween.color(menuBottom, 1, menuBottom.color, curColor, {
			onComplete: function(twn:FlxTween)
			{
				colorTween = null;
			}
		});

		super.update(elapsed);
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.updateHitbox();
			spr.alpha = 0;

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				spr.alpha = 1;
				var add:Float = 0;
				if (menuItems.length > 4)
				{
					add = menuItems.length * 8;
				}
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
				spr.centerOffsets();
			}
		});
	}
}
