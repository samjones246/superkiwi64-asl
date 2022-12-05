state("SuperKiwi64") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "SuperKiwi64";
    vars.Helper.LoadSceneManager = true;

    string[] levelNames = {
        "Forest Village", "Mushroom Dorf",
        "Train Station", "High Towers",
        "Temple", "Chamber",
        "Pirate Island", "Big Bay",
        "Jungle Course", "Kiwi 64"
    };
    settings.Add("split_enter", false, "Split on enter level");
    settings.Add("split_exit", true, "Split on exit level");
    for (int i=2;i<=11;i++) {
        var description = "" + (i-1) + " - " + levelNames[i-2];
        settings.Add("split_enter_"+i, false, description, "split_enter");
        settings.Add("split_exit_"+i, i <= 9, description, "split_exit");
    }

    settings.Add("split_powerstone", false, "Split on powerstone collected");
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.Helper["powerstones"] = mono.Make<int>("GameManager", "singleton", "collectedCells");
        vars.Helper["lastPos"] = mono.Make<IntPtr>("GameManager", "singleton", "myPlayerSystem", "LastPos");
        vars.Helper["nextScene"] = mono.Make<int>("GameManager", "singleton", "NextLevelID");

        return true;
    });
    vars.prevScene = -1;
}

update
{
    if (vars.Helper.Scenes.Active.Name != "")
    {
        current.scene = vars.Helper.Scenes.Active.Index;
    }

    if (old.scene != current.scene) {
        vars.Log("Scene Change: " + current.scene + ": " + vars.Helper.Scenes.Active.Name);
    }
}

start
{
    return old.lastPos == IntPtr.Zero && current.lastPos != IntPtr.Zero;
}

split
{
    // Level change
    if (current.nextScene != old.nextScene && current.nextScene != 0) {
        vars.Log("scene: " + current.scene);
        vars.Log("nextScene: " + current.nextScene);
        // Enter plane
        if (current.nextScene == 12) {
            return true;
        }

        // Enter hub
        if (current.nextScene == 1) {
            vars.prevScene = 1;
            int target = current.scene != 0 ? current.scene : vars.prevScene;
            return settings["split_exit_"+target];
        }

        // Enter level
        vars.prevScene = current.nextScene;
        return settings["split_enter_"+current.nextScene];
    }

    // Collect powerstone
    if (current.powerstones != old.powerstones) {
        return settings["split_powerstone"];
    }
}

isLoading
{
    return current.nextScene != 0 || current.scene == 0;
}

exit
{
    vars.Helper.Timer.Reset();
}
