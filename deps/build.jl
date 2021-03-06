using Compat
using BinDeps

libdir_opt = ""

@BinDeps.setup

cxx_wrap_dir = Pkg.dir("CxxWrap","deps","usr","lib","cmake")

liblciowrap = library_dependency("liblciowrap")
prefix=joinpath(BinDeps.depsdir(liblciowrap),"usr")
lcioversion = "v02-07-02"
# if the LCIO environment has been sourced, use it. Otherwise, download from svn
lciowrap_srcdir = joinpath(BinDeps.depsdir(liblciowrap), "src", "lciowrap")
lciowrap_builddir = joinpath(BinDeps.depsdir(liblciowrap),"builds","lciowrap")
lcio_srcdir = haskey(ENV, "LCIO") ? ENV["LCIO"] : joinpath(lciowrap_builddir, lcioversion)
lib_prefix = @static is_windows() ? "" : "lib"
lib_suffix = @static is_windows() ? "dll" : (@static is_apple() ? "dylib" : "so")

genopt = "Unix Makefiles"

# LCIOConfig.cmake needs to be available. If not there, check out the LCIO source
# unfortunately, this only works on POSIX at the moment
provides(BuildProcess,
  (@build_steps begin
    FileRule(joinpath(lcio_srcdir, "LCIOConfig.cmake"), @build_steps begin
        `svn co svn://svn.freehep.org/lcio/tags/"$lcioversion" "$lcio_srcdir"`
        CreateDirectory(joinpath(lcio_srcdir, "build"))
        @build_steps begin
            ChangeDirectory(joinpath(lcio_srcdir, "build"))
            `cmake ..`
            `make`
            `make install`
        end
    end)
    CreateDirectory(lciowrap_builddir)
    @build_steps begin
      ChangeDirectory(lciowrap_builddir)
      FileRule(joinpath(prefix, "lib$libdir_opt", "$(lib_prefix)lciowrap.$lib_suffix"), @build_steps begin
      	`cmake -G "$genopt" -DCMAKE_INSTALL_PREFIX="$prefix" -DCMAKE_BUILD_TYPE="Release" -DCxxWrap_DIR="$cxx_wrap_dir" -DLIBDIR_SUFFIX="$libdir_opt" -DLCIO_INSTALLDIR="$lcio_srcdir" $lciowrap_srcdir`
      	`cmake --build . --config Release --target install`
      end)
    end
  end),liblciowrap)

deps = [liblciowrap]

@BinDeps.install Dict([(:liblciowrap, :_l_lciowrap)])
