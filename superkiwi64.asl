state("SuperKiwi64") { }

startup
{
    vars.Log = (Action<object>)((output) => print("[SuperKiwi64 ASL] " + output));
    var bytes = File.ReadAllBytes(@"Components\LiveSplit.ASLHelper.bin");
	var type = Assembly.Load(bytes).GetType("ASLHelper.Unity");
	vars.Helper = Activator.CreateInstance(type, timer, this);
	vars.Helper.LoadSceneManager = true;

    vars.TimerModel = new TimerModel { CurrentState = timer };

    var levelNames = new String[] {
        "Forest Village", "Mushroom Dorf", 
        "Train Station", "High Towers",
        "Temple", "Chamber",
        "Pirate Island", "Big Bay"
    };
    settings.Add("split_enter", false, "Split on enter level");
    settings.Add("split_exit", true, "Split on exit level");
    for (int i=2;i<=9;i++) {
        var description = "" + (i-1) + " - " + levelNames[i-2];
        settings.Add("split_enter_"+i, false, description, "split_enter");
        settings.Add("split_exit_"+i, true, description, "split_exit");
    }

    settings.Add("split_powerstone", false, "Split on powerstone collected");
}


init
{
    vars.Helper.TryOnLoad = (Func<dynamic, bool>)(mono =>
	{
        var GameManager = mono.GetClass("GameManager");
        var PlayerSystem = mono.GetClass("PlayerSystem");
        vars.Helper["collectedCells"] = GameManager.Make<int>("singleton", "collectedCells");
        vars.Helper["LastPos"] = GameManager.Make<IntPtr>("singleton", "myPlayerSystem", PlayerSystem["LastPos"]);
        vars.Helper["NextLevelID"] = GameManager.Make<int>("singleton", "NextLevelID");
        return true;
    });

    vars.Helper.Load();

    vars.init = true;
}

update
{
    if (!vars.Helper.Loaded) return false;
	
	vars.Helper.Update();
	
	if (vars.Helper.Scenes.Active.Name != "")
	{
		current.scene = vars.Helper.Scenes.Active.Index;
	}

    current.nextScene = vars.Helper["NextLevelID"].Current;
    current.powerstones = vars.Helper["collectedCells"].Current;
 
	if (old.scene != current.scene) { 
        vars.Log(String.Concat("Scene Change: ", current.scene, ": ", vars.Helper.Scenes.Active.Name));
    }
}

start
{
    return vars.Helper["LastPos"].Old == IntPtr.Zero && vars.Helper["LastPos"].Changed;
}

split
{
    // Level change
    if (current.nextScene != old.nextScene) {
        // Enter plane
        if (current.nextScene == 12) {
            return true;
        }

        // Enter hub
        if (current.nextScene == 1) {
            return settings["split_exit_"+old.scene];
        }

        // Enter level
        return settings["split_enter_"+current.scene];
    }

    // Collect powerstone
    if (current.powerstones != old.powerstones) {
        return settings["split_powerstone"];
    }
    return false;
}

isLoading
{
    return current.nextScene != 0;
}

exit
{
    vars.TimerModel.Reset();
}