module UsesPreferences
using Preferences

const compile_time_pref = @load_preference("compile_time", "not set")

Base.@ccallable function dump_prefs()::Nothing
    run_time_pref = @load_preference("run_time", "not set")
    @info(
        "Preference dump",
        active_project=Base.active_project(),
        load_path=Base.load_path(),
        project_search_path=Base.env_project_file.(reverse(Base.load_path())),
        compile_time_pref,
        run_time_pref,
    )
    return nothing
end

end # module UsesPreferences
