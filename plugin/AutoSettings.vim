" File:         plugin/AutoSettings.vim
" Description:  Automatically updates vim local settings depending on current file path and user-defined build configurations.
" Author:       yssl <http://github.com/yssl>
" License:      MIT License

if exists("g:loaded_autosettings") || &cp
	finish
endif
let g:loaded_autosettings	= 1
let s:keepcpo           = &cpo
set cpo&vim
"""""""""""""""""""""""""""""""""""""""""""""

" initialize python
python << EOF
import vim
import os, fnmatch

def getWinName(bufname, buftype):
	if bufname==None:
		if len(buftype)>0:
			winname = '[%s]'%buftype
		else:
			winname = '[No Name]'
	else:
		if len(buftype)>0:
			winname = os.path.basename(bufname)
			winname = '[%s] %s'%(buftype, winname)
		else:
			winname = bufname
	return winname

# setting: vimscript dictionary
# ex) {
#		\'localMaps':[
#			\[['nnoremap', 'inoremap', 'cnoremap', 'vnoremap'], '<F9>', ':w<CR>:BuildAndViewTexPdf<CR>:call QuickfixCWindowError()<CR><C-l><C-l>'],
#			\[['nnoremap', 'inoremap', 'cnoremap', 'vnoremap'], '<C-F9>', ':w<CR>:BuildTexPdf<CR>:call QuickfixCWindowError()<CR><C-l>'],
#			\[['nnoremap'], '<Leader>fs', ':call Tex_ForwardSearchLaTeX()<CR>'],
#		\],
#		\'setLocals':[
#			\'wrap',
#			\'shiftwidth=4',
#			\'expandtab',
#			\'makeprg=stdbuf\ -i0\ -o0\ -e0\ python\ %',
#		\],
#	\}
# 
# example for <expr> mapping - following two statements are identical
# exec 'nnoremap <buffer> <expr> <Leader>sc ":echo expand(\"%:p\")\<CR>"'
# exec 'nnoremap <buffer> <Leader>sc :echo expand("%:p")<CR>'
def applySetting(setting):
	if 'setLocals' in setting:
		for setparam in setting['setLocals']:
			vim.command('exec \'setlocal %s\''%setparam)
	if 'localMaps' in setting:
		for mapdata in setting['localMaps']:
			shortcut = mapdata[1]
			command = mapdata[2]
			for mapcmd in mapdata[0]:
				if mapcmd[0]!='n':	# add <ESC> when non-normal mode mapping
					command = '<ESC>'+command
				vim.command('exec \'%s <buffer> %s %s\''%(mapcmd, shortcut, command))
	if 'localMapsExpr' in setting:
		for mapdata in setting['localMapsExpr']:
			shortcut = mapdata[1]
			command = mapdata[2]
			for mapcmd in mapdata[0]:
				if mapcmd[0]!='n':	# add <ESC> when non-normal mode mapping
					command = command[:1]+'<ESC>'+command[1:]
				vim.command('exec \'%s <buffer> <expr> %s \'%s\'\''%(mapcmd, shortcut, command))

def applyBuildConfig(setting):
	if 'buildConfigNames' in setting:
		pass
	if 'buildConfigs' in setting:
		current_configname = setting['buildConfigNames'][0]
		current_config = setting['buildConfigs'][current_configname]
		applySetting(current_config)

		## local setting for current file path & build configuration
		#buildsettings = vim.eval('g:autosettings_for_build')
		#matched = False
		#for patterns, setting in buildsettings:
		#	for pattern in patterns:
		#		if fnmatch.fnmatch(filepath, pattern):
		#			matched_build_pattern = pattern
		#			matched_build_setting = setting
		#
		#			# common config
		#			if 'commonConfig' in setting:
		#				applySetting(setting['commonConfig'])
		#
		#			# specific config
		#			if pattern not in current_pattern_configname:
		#				current_configname = setting['defaultConfigName']
		#				current_pattern_configname[pattern] = current_configname
		#
		#			current_config = setting['configs'][current_configname]
		#			#print current_config
		#
		#			applySetting(current_config)
		#
		#			matched = True
		#			break
		#	if matched:
		#		break


matched_local_patterns = []
matched_local_settings = []
matched_build_pattern = ''
matched_build_setting = {}
current_pattern_configname = {}
EOF

" global variables
if !exists('g:autosettings_settings')
	let g:autosettings_settings = []
endif
if !exists('g:autosettings_for_build')
	let g:autosettings_for_build = []
endif

" commands
command! AutoSettingsPrint call s:PrintCurrentSetting()

" autocmd
augroup AutoSettingsAutoCmds
	autocmd!
	autocmd BufEnter * call s:UpdateSetting()
augroup END

" functions
fun! s:UpdateSetting()
python << EOF
filepath = vim.eval('expand(\'<afile>:p\')')
del matched_local_patterns[:]
del matched_local_settings[:]
matched_build_pattern = ''
matched_build_setting = {}

localsettings = vim.eval('g:autosettings_settings')
for patterns, setting in localsettings:
	for pattern in patterns:
		if fnmatch.fnmatch(filepath, pattern):
			matched_local_patterns.append(pattern)
			matched_local_settings.append(setting)

			# process 'setLocals', 'localMaps', 'localMapsExpr'
			applySetting(setting)

			# process 'buildConfigNames', 'buildConfigs'
			applyBuildConfig(setting)

			break

			## local setting for current file path & build configuration
			#buildsettings = vim.eval('g:autosettings_for_build')
			#matched = False
			#for patterns, setting in buildsettings:
			#	for pattern in patterns:
			#		if fnmatch.fnmatch(filepath, pattern):
			#			matched_build_pattern = pattern
			#			matched_build_setting = setting
			#
			#			# common config
			#			if 'commonConfig' in setting:
			#				applySetting(setting['commonConfig'])
			#
			#			# specific config
			#			if pattern not in current_pattern_configname:
			#				current_configname = setting['defaultConfigName']
			#				current_pattern_configname[pattern] = current_configname
			#
			#			current_config = setting['configs'][current_configname]
			#			#print current_config
			#
			#			applySetting(current_config)
			#
			#			matched = True
			#			break
			#	if matched:
			#		break
EOF
endfun

fun! s:PrintCurrentSetting()
python << EOF
bufname = vim.current.buffer.name
buftype = vim.eval('getbufvar(winbufnr("%"), \'&buftype\')')
winname = getWinName(bufname, buftype)
print 'AutoSettings.vim settings for: %s'%winname
print ' '

for i in range(len(matched_local_patterns)):
	print matched_local_patterns[i]
	print matched_local_settings[i]
print ' '

EOF
endfun

"print 'Predefined Config Names in the Matched Pattern:'
"if 'configNames' in matched_build_setting:
	"print matched_build_setting['configNames']
"print ' '

"print 'Current Config Name for the Matched Pattern:'
"if matched_build_pattern in current_pattern_configname:
	"current_config_name = current_pattern_configname[matched_build_pattern]
	"print current_config_name
"print ' '

"print 'Current Build Config:'
"if 'configs' in matched_build_setting:
	"print matched_build_setting['configs'][current_config_name]
"print ' '

"""""""""""""""""""""""""""""""""""""""""""""
let &cpo= s:keepcpo
unlet s:keepcpo
