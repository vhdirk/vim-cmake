" cmake.vim - Vim plugin to make working with CMake a little nicer
" Maintainer:   Dirk Van Haerenborgh <http://vhdirk.github.com/>
" Version:      0.3

let s:cmake_plugin_version = '0.2'

if exists('loaded_cmake_plugin')
  finish
endif
let loaded_cmake_plugin = 1

" Allow the user to select custom build and source directories
" Off by default
if !exists('g:cmake_custom_dirs')
  let g:cmake_custom_dirs = 0
endif

let s:build_dir = ''
let s:source_dir = '' 

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
  if g:cmake_custom_dirs
    let s:build_dir = input ('Build directory: ', getcwd())  
    let s:source_dir = input ('Source directory: ', getcwd())
    echo ' '
  else
    let s:build_dir = finddir('build', '.;')
    let s:source_dir = ".."
  endif

  if s:build_dir !=""
    let &makeprg='cmake --build ' . s:build_dir

    exec 'cd' s:fnameescape(s:build_dir)

    let l:argument=[]
    let l:environment=[]
    if exists('g:cmake_install_prefix')
      let l:argument+=  [ '-DCMAKE_INSTALL_PREFIX:FILEPATH='  . g:cmake_install_prefix ]
    endif
    if exists('g:cmake_build_type' )
      let l:argument+= [ '-DCMAKE_BUILD_TYPE:STRING='         . g:cmake_build_type ]
    endif
    if exists('g:cmake_cxx_compiler')
      let l:environment+= [ 'CXX="'                           . g:cmake_cxx_compiler . '"']
    endif
    if exists('g:cmake_c_compiler')
      let l:environment+= [ 'CC="'                            . g:cmake_c_compiler . '"' ]
    endif
    if exists('g:cmake_build_shared_libs')
      let l:argument+= [ '-DBUILD_SHARED_LIBS:BOOL='          . g:cmake_build_shared_libs ]
    endif

    let l:environmentstr = join(l:environment, ' ')
    let l:argumentstr = join(l:argument, ' ')

    let s:cmd = l:environmentstr . ' cmake ' . l:argumentstr . join(a:000) . ' ' . s:source_dir . ' '
    echo s:cmd
    let s:res = system(s:cmd)
    echo s:res

    exec 'cd - '
  else
    echo 'Unable to find build directory.'
  endif

endfunction

function! s:cmakeclean()

  if g:cmake_custom_dirs
    if s:build_dir !=''
      exec 'cd' s:fnameescape(s:build_dir) 
      echo system('make clean')
      echo system('rm -r CMakeFiles' )
      echo system('rm CMakeCache.txt' )
      echo system('rm cmake_install.cmake' )
      echo 'Build directory has been cleaned.'
      exec 'cd - '
    else
      echo "Unable to find build directory."
    endif
  else
    if s:build_dir !=""
      echo system("rm -r " . s:build_dir. "/*" )
      echo 'Build directory has been cleaned.'
    else
      echo 'Unable to find build directory.'
    endif
  endif

endfunction
