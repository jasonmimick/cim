" Vim syntax file
" Language:	Caché ObjectScript
" Maintainer:	Jason Mimick <jason.mimick@intersystems.com>
" Last Change:	Mon June 24 13:56:37 PDT 2013
" Filenames:	*.cls
"
" REFERENCES:

if exists("b:current_syntax")
    finish
endif

let s:cs_cpo_save = &cpo
set cpo&vim


" type
" syn keyword csType			bool byte char decimal double float int long object sbyte short string uint ulong ushort void
syn keyword csType		%Integer %String %Float  	
" storage
syn keyword csStorage		class Class Property property Parameter parameter Method method ClassMethod Query query XData xdata Storage storage as As #dim #include
" repeat / condition / label
syn keyword csRepeat		b break continue do d f for foreach g goto return while q quit set s w write 
syn keyword csConditional	: else if switch
syn keyword csLabel			case default
" there's no :: operator in C#
syn match csOperatorError		display +::+
" user labels (see [1] 8.6 Statements)
syn match   csLabel			display +^\s*\I\i*\s*:\([^:]\)\@=+
" modifier
syn keyword csModifier			abstract const extern internal override private protected public readonly sealed static virtual volatile extends Extends Internal
" constant
syn keyword csConstant			false null true 1 0
" exception
syn keyword csException			try catch finally throw

" TODO:
syn keyword csUnspecifiedStatement	as base checked event fixed in is lock new operator out params ref sizeof stackalloc this typeof unchecked unsafe using
" TODO:
syn keyword csUnsupportedStatement	add remove value
" TODO:
syn keyword csUnspecifiedKeyword	explicit implicit


" Contextual Keywords
syn match csContextualStatement	/\<yield[[:space:]\n]\+\(return\|break\)/me=s+5
syn match csContextualStatement	/\<partial[[:space:]\n]\+\(class\|struct\|interface\)/me=s+7
syn match csContextualStatement	/\<\(get\|set\)[[:space:]\n]*{/me=s+3
syn match csContextualStatement	/\<where\>[^:]\+:/me=s+5

" Comments
"
" PROVIDES: @csCommentHook
"
" TODO: include strings ?
"
syn keyword csTodo		contained TODO FIXME XXX NOTE
syn region  csComment		start="/\*"  end="\*/" contains=@csCommentHook,csTodo,@Spell
syn match   csComment		"//.*$" contains=@csCommentHook,csTodo,@Spell

" xml markup inside '///' comments
syn cluster xmlRegionHook	add=csXmlCommentLeader
syn cluster xmlCdataHook	add=csXmlCommentLeader
syn cluster xmlStartTagHook	add=csXmlCommentLeader
syn keyword csXmlTag		contained Libraries Packages Types Excluded ExcludedTypeName ExcludedLibraryName
syn keyword csXmlTag		contained ExcludedBucketName TypeExcluded Type TypeKind TypeSignature AssemblyInfo
syn keyword csXmlTag		contained AssemblyName AssemblyPublicKey AssemblyVersion AssemblyCulture Base
syn keyword csXmlTag		contained BaseTypeName Interfaces Interface InterfaceName Attributes Attribute
syn keyword csXmlTag		contained AttributeName Members Member MemberSignature MemberType MemberValue
syn keyword csXmlTag		contained ReturnValue ReturnType Parameters Parameter MemberOfPackage
syn keyword csXmlTag		contained ThreadingSafetyStatement Docs devdoc example overload remarks returns summary
syn keyword csXmlTag		contained threadsafe value internalonly nodoc exception param permission platnote
syn keyword csXmlTag		contained seealso b c i pre sub sup block code note paramref see subscript superscript
syn keyword csXmlTag		contained list listheader item term description altcompliant altmember

syn cluster xmlTagHook add=csXmlTag

syn match   csXmlCommentLeader	+\/\/\/+    contained
syn match   csXmlComment	+\/\/\/.*$+ contains=csXmlCommentLeader,@csXml,@Spell
syntax include @csXml syntax/xml.vim
hi def link xmlRegion Comment


" [1] 9.5 Pre-processing directives
syn region	csPreCondit
    \ start="^\s*#\s*\(define\|undef\|if\|elif\|else\|endif\|line\|error\|warning\)"
    \ skip="\\$" end="$" contains=csComment keepend
syn region	csRegion matchgroup=csPreCondit start="^\s*#\s*region.*$"
    \ end="^\s*#\s*endregion" transparent fold contains=TOP



" Strings and constants
syn match   csSpecialError	contained "\\."
syn match   csSpecialCharError	contained "[^']"
" [1] 9.4.4.4 Character literals
syn match   csSpecialChar	contained +\\["\\'0abfnrtvx]+
" unicode characters
syn match   csUnicodeNumber	+\\\(u\x\{4}\|U\x\{8}\)+ contained contains=csUnicodeSpecifier
syn match   csUnicodeSpecifier	+\\[uU]+ contained
syn region  csVerbatimString	start=+@"+ end=+"+ skip=+""+ contains=csVerbatimSpec,@Spell
syn match   csVerbatimSpec	+@"+he=s+1 contained
syn region  csString		start=+"+  end=+"+ end=+$+ contains=csSpecialChar,csSpecialError,csUnicodeNumber,@Spell
syn match   csCharacter		"'[^']*'" contains=csSpecialChar,csSpecialCharError
syn match   csCharacter		"'\\''" contains=csSpecialChar
syn match   csCharacter		"'[^\\]'"
syn match   csNumber		"\<\(0[0-7]*\|0[xX]\x\+\|\d\+\)[lL]\=\>"
syn match   csNumber		"\(\<\d\+\.\d*\|\.\d\+\)\([eE][-+]\=\d\+\)\=[fFdD]\="
syn match   csNumber		"\<\d\+[eE][-+]\=\d\+[fFdD]\=\>"
syn match   csNumber		"\<\d\+\([eE][-+]\=\d\+\)\=[fFdD]\>"

" The default highlighting.
hi def link csType			Type
hi def link csStorage			StorageClass
hi def link csRepeat			Repeat
hi def link csConditional		Conditional
hi def link csLabel			Label
hi def link csModifier			StorageClass
hi def link csConstant			Constant
hi def link csException			Exception
hi def link csUnspecifiedStatement	Statement
hi def link csUnsupportedStatement	Statement
hi def link csUnspecifiedKeyword	Keyword
hi def link csContextualStatement	Statement
hi def link csOperatorError		Error

hi def link csTodo			Todo
hi def link csComment			Comment

hi def link csSpecialError		Error
hi def link csSpecialCharError		Error
hi def link csString			String
hi def link csVerbatimString		String
hi def link csVerbatimSpec		SpecialChar
hi def link csPreCondit			PreCondit
hi def link csCharacter			Character
hi def link csSpecialChar		SpecialChar
hi def link csNumber			Number
hi def link csUnicodeNumber		SpecialChar
hi def link csUnicodeSpecifier		SpecialChar

" xml markup
hi def link csXmlCommentLeader		Comment
hi def link csXmlComment		Comment
hi def link csXmlTag			Statement

let b:current_syntax = "cls"

let &cpo = s:cs_cpo_save
unlet s:cs_cpo_save

" vim: ts=8
