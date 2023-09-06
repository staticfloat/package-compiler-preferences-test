using Preferences, Pkg, UsesPreferences

function run_code(code::String)
    run(`$(Base.julia_cmd()) --project=. -e $(code)`)
end

# Reset:
rm(joinpath(@__DIR__, "LocalPreferences.toml"); force=true)
@warn("Initial setup")
run_code("using UsesPreferences; UsesPreferences.dump_prefs()")

# First test, no PackageCompiler, just set preferences and load the package.
# This should trigger recompilation, both compile_time and run_time should show `set initially`:
set_preferences!(UsesPreferences, "compile_time" => "set initially", "run_time" => "set initially"; force=true)
@warn("Setting preferences normally")
run_code("using UsesPreferences; UsesPreferences.dump_prefs()")

# Next, test changing the preferences halfway through execution
# Note that `compile_time_pref` doesn't change, because it's only read at compile-time.
@warn("Changing preferences at runtime")
run_code("""
using UsesPreferences, Preferences
set_preferences!(UsesPreferences, "compile_time" => "set at runtime", "run_time" => "set at runtime"; force=true)
UsesPreferences.dump_prefs()
""")

# Next, let's start package compiling some things!
using PackageCompiler

# Use a C helper to run PackageCompiler output
function load_lib(dirname::String)
    if !isfile("lib_executor")
        run(`gcc -O2 -o ./lib_executor ./lib_executor.c`)
    end
    path_var = Sys.isapple() ? "DYLD_LIBRARY_PATH" : "LD_LIBRARY_PATH"
    soext = Sys.isapple() ? "dylib" : "so"
    run(addenv(
        `./lib_executor $(dirname)/lib/libusespreferences.$(soext) --project=.`,
        path_var => "$(joinpath(dirname, "lib")):$(joinpath(dirname, "lib", "julia"))",
    ))
end

# Create a library with no preferences set
rm(joinpath(@__DIR__, "LocalPreferences.toml"); force=true)
if !isdir("build/noprefs")
    PackageCompiler.create_library("UsesPreferences", "build/noprefs", lib_name="libusespreferences")
end
@warn("C library, no preferences set")
load_lib("build/noprefs")

# Create a library with preferences set, we expect to see `set initially` for all preferences here.
set_preferences!(UsesPreferences, "compile_time" => "set initially", "run_time" => "set initially"; force=true)
if !isdir("build/initial_prefs")
    PackageCompiler.create_library("UsesPreferences", "build/initial_prefs", lib_name="libusespreferences")
end
@warn("C library, preferences set during compilation")
load_lib("build/initial_prefs")

# Now, change some of those preferences and run again, we expect the compile time preference to still
# say `set initially`, but the runtime preference should see that things were changed.
set_preferences!(UsesPreferences, "compile_time" => "set at runtime", "run_time" => "set at runtime"; force=true)
@warn("C library, preferences modified after compilation")
load_lib("build/initial_prefs")

