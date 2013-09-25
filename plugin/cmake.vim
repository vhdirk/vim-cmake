" cmake.vim - Vim plugin to make working with CMake a little nicer
" Maintainer:   Dirk Van Haerenborgh <http://vhdirk.github.com/>
" Version:      0.2

let s:cmake_plugin_version = '0.2'

if exists("loaded_cmake_plugin")
  finish
endif
let loaded_cmake_plugin = 1

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

  let s:build_dir = finddir('build', '.;')
  let &makeprg='cmake --build ' . shellescape(s:build_dir) . ' --target '

  exec 'cd' s:fnameescape(s:build_dir)

  let s:cleanbuild = 0
  let l:argument=[]
  if exists("g:cmake_install_prefix")
    let l:argument+=  [ "-DCMAKE_INSTALL_PREFIX:FILEPATH="  . g:cmake_install_prefix ]
  endif
  if exists("g:cmake_build_type" )
    let l:argument+= [ "-DCMAKE_BUILD_TYPE:STRING="         . g:cmake_build_type ]
  endif
  if exists("g:cmake_cxx_compiler")
    let l:argument+= [ "-DCMAKE_CXX_COMPILER:FILEPATH="     . g:cmake_cxx_compiler ]
    let s:cleanbuild = 1
  endif
  if exists("g:cmake_c_compiler")
    let l:argument+= [ "-DCMAKE_C_COMPILER:FILEPATH="       . g:cmake_c_compiler ]
    let s:cleanbuild = 1
  endif
  if exists("g:cmake_build_shared_libs")
    let l:argument+= [ "-DBUILD_SHARED_LIBS:BOOL="          . g:cmake_build_shared_libs ]
  endif

  let l:argumentstr = join(l:argument, " ")

  if s:cleanbuild > 0
    echo system("rm -r *" )
  endif

  let s:cmd = 'cmake '. l:argumentstr . join(a:000) .' .. '
  echo s:cmd
  let s:res = system(s:cmd)
  echo s:res

  exec 'cd - '

endfunction

function! s:cmakeclean()

  let s:build_dir = finddir('build', '.;')
  echo system("rm -r " . s:build_dir. "/*" )
  echo "Build directory has been cleaned."

endfunction
