" cmake.vim - Vim plugin to make working with CMake a little nicer
" Maintainer:   Dirk Van Haerenborgh <http://vhdirk.github.com/>
" Version:      0.2

let s:cmake_plugin_version = '0.2'

if exists("loaded_cmake_plugin")
  finish
endif

" We set this variable here even though the plugin may not actually be loaded
" because the executable is not found. Otherwise the error message will be
" displayed more than once.
let loaded_cmake_plugin = 1

if !executable("cmake")
  echoerr "vim-cmake requires cmake executable. Please make sure it is installed and on PATH."
  finish
endif

function! s:find_build_dir()
  let g:cmake_build_dir = get(g:, 'cmake_build_dir', 'build')
  let s:build_dir = finddir(g:cmake_build_dir, '.;')

  if s:build_dir == ""
    " Find build directory in path of current file
    let s:build_dir = finddir(g:cmake_build_dir, expand("%:p:h") . ';')
  endif
endfunction

" Configure the cmake project in the currently set build dir.
"
" :param force: Force configuration even if CMakeCache.txt already exists in
" build dir. This will override any of the following variables if the
" corresponding vim variable is set:
"   * CMAKE_INSTALL_PREFIX
"   * CMAKE_BUILD_TYPE
"   * CMAKE_BUILD_SHARED_LIBS
" In addition, previous configuration files will be deleted if the
" corresponding vim variables for the following are set:
"   * CMAKE_CXX_COMPILER
"   * CMAKE_C_COMPILER
"   * The generator
"
" Will do nothing if the project is already configured and force is disabled.
function! s:cmake_configure(force)
  if filereadable(s:build_dir . "/CMakeCache.txt") && !a:force
    " Only change values of variables, if project is not configured
    " already, otherwise we override existing configuration.
    return
  endif

  exec 'cd' s:fnameescape(s:build_dir)

  let s:cleanbuild = 0
  let l:argument = []
  if exists("g:cmake_project_generator")
    let l:argument += [ "-G \"" . g:cmake_project_generator . "\"" ]
    let s:cleanbuild = 1
  endif
  if exists("g:cmake_install_prefix")
    let l:argument += [ "-DCMAKE_INSTALL_PREFIX:FILEPATH="  . g:cmake_install_prefix ]
  endif
  if exists("g:cmake_build_type" )
    let l:argument += [ "-DCMAKE_BUILD_TYPE:STRING="         . g:cmake_build_type ]
  endif
  if exists("g:cmake_cxx_compiler")
    let l:argument += [ "-DCMAKE_CXX_COMPILER:FILEPATH="     . g:cmake_cxx_compiler ]
    let s:cleanbuild = 1
  endif
  if exists("g:cmake_c_compiler")
    let l:argument += [ "-DCMAKE_C_COMPILER:FILEPATH="       . g:cmake_c_compiler ]
    let s:cleanbuild = 1
  endif
  if exists("g:cmake_build_shared_libs")
    let l:argument += [ "-DBUILD_SHARED_LIBS:BOOL="          . g:cmake_build_shared_libs ]
  endif

  let l:argumentstr = join(l:argument, " ")

  if s:cleanbuild > 0
    echo system("rm -r *" )
  endif

  let s:cmd = 'cmake '. l:argumentstr . " " . join(a:000) .' .. '
  echo s:cmd
  let s:res = system(s:cmd)
  echo s:res

  exec 'cd -'
endfunction

" Utility function
" Thanks to tpope/vim-fugitive
function! s:fnameescape(file) abort
  if exists('*fnameescape')
    return fnameescape(a:file)
  else
    return escape(a:file," \t\n*?[{`$\\%#'\"|!<")
  endif
endfunction

" Public Interface:
command! -nargs=? CMake call s:cmake(<f-args>)
command! CMakeClean call s:cmakeclean()

function! s:cmake(...)
  call s:find_build_dir()

  if s:build_dir != ""
    let &makeprg = 'cmake --build ' . shellescape(s:build_dir) . ' --target'
    call s:cmake_configure(0)
  else
    echom "Unable to find build directory."
  endif

endfunction

function! s:cmakeclean()
  call s:find_build_dir()

  if s:build_dir != ""
    echo system("rm -r '" . s:build_dir. "'/*")
    echom "Build directory has been cleaned."
  else
    echom "Unable to find build directory."
  endif

endfunction
