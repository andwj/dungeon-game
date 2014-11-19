" Vim syntax file
" Language:	Quake-C
" based on 'c.vim' by Bram Moolenaar
" blame Andrew Apted for all problems here

" HOW TO USE THIS FILE (on Linux)
" 1. create $(HOME)/.vim unless it already exists
" 2. create $(HOME)/.vim/syntax directory, place this file in it
" 3. create $(HOME)/.vim/filetype.vim with following contents:
"
" augroup filetypedetect
" au BufNewFile,BufRead *.qc     setf qc
" augroup END
"
" 4. edit Quake-C files and be happy


" Quit when a (custom) syntax file was already loaded
if exists("b:current_syntax")
  finish
endif

" andrewj: always parse from start of file [slow, but accurate]
syn sync fromstart

" A bunch of useful C keywords
syn keyword	qcStatement	goto break return continue
syn keyword	qcLabel		case default
syn keyword	qcConditional	if else switch
syn keyword	qcRepeat	while for do

syn keyword	qcTodo		contained TODO FIXME WISH OPTIMISE OPTIMIZE

" It's easy to accidentally add a space after a backslash that was intended
" for line continuation.  Some compilers allow it, which makes it
" unpredicatable and should be avoided.
syn match	qcBadContinuation contained "\\\s\+$"

" qcCommentGroup allows adding matches for special things in comments
syn cluster	qcCommentGroup	contains=qcTodo,qcBadContinuation

" String and Character constants
" Highlight special characters (those which have a backslash) differently
syn match	qcSpecial	display contained "\\\(x\x\+\|\o\{1,3}\|.\|$\)"

syn match	qcFormat		display "%\(\d\+\$\)\=[-+' #0*]*\(\d*\|\*\|\*\d\+\$\)\(\.\(\d*\|\*\|\*\d\+\$\)\)\=\([hlL]\|ll\)\=\([bdiuoxXDOUfeEgGcCsSpn]\|\[\^\=.[^]]*\]\)" contained
syn match	qcFormat		display "%%" contained
syn region	qcString		start=+L\="+ skip=+\\\\\|\\"+ end=+"+ contains=qcSpecial,qcFormat,@Spell extend
" qcCppString: same as qcString, but ends at end of line
syn region	qcCppString	start=+L\="+ skip=+\\\\\|\\"\|\\$+ excludenl end=+"+ end='$' contains=qcSpecial,qcFormat,@Spell

syn match	qcCharacter	"L\='[^\\]'"
syn match	qcCharacter	"L'[^']*'" contains=qcSpecial
syn match	qcSpecialError	"L\='\\[^'\"?\\abfnrtv]'"
syn match	qcSpecialCharacter "L\='\\['\"?\\abfnrtv]'"
syn match	qcSpecialCharacter display "L\='\\\o\{1,3}'"
syn match	qcSpecialCharacter display "'\\x\x\{1,2}'"
syn match	qcSpecialCharacter display "L'\\x\x\+'"

" This should be before qcErrInParen to avoid problems with #define ({ xxx })
syntax match qcCurlyError "}"
syntax region	qcBlock		start="{" end="}" contains=ALLBUT,qcBadBlock,qcCurlyError,@qcParenGroup,qcErrInParen,qcCppParen,qcErrInBracket,qcCppBracket,qcCppString,@Spell fold

"catch errors caused by wrong parenthesis and brackets
" also accept <% for {, %> for }, <: for [ and :> for ] (C99)
" But avoid matching <::.
syn cluster	qcParenGroup	contains=qcParenError,qcIncluded,qcSpecial,qcCommentSkip,qcCommentString,qcComment2String,@qcCommentGroup,qcCommentStartError,qcUserCont,qcUserLabel,qcBitField,qcOctalZero,@qcCppOutInGroup,qcFormat,qcNumber,qcFloat,qcOctal,qcOctalError,qcNumbersCom
syn region	qcParen		transparent start='(' end=')' end='}'me=s-1 contains=ALLBUT,qcBlock,@qcParenGroup,qcCppParen,qcErrInBracket,qcCppBracket,qcCppString,@Spell
" qcCppParen: same as qcParen but ends at end-of-line; used in qcDefine
syn region	qcCppParen	transparent start='(' skip='\\$' excludenl end=')' end='$' contained contains=ALLBUT,@qcParenGroup,qcErrInBracket,qcParen,qcBracket,qcString,@Spell
syn match	qcParenError	display "[\])]"
syn match	qcErrInParen	display contained "[\]{}]\|<%\|%>"
syn region	qcBracket	transparent start='\[\|<::\@!' end=']\|:>' end='}'me=s-1 contains=ALLBUT,qcBlock,@qcParenGroup,qcErrInParen,qcCppParen,qcCppBracket,qcCppString,@Spell
" qcCppBracket: same as qcParen but ends at end-of-line; used in qcDefine
syn region	qcCppBracket	transparent start='\[\|<::\@!' skip='\\$' excludenl end=']\|:>' end='$' contained contains=ALLBUT,@qcParenGroup,qcErrInParen,qcParen,qcBracket,qcString,@Spell
syn match	qcErrInBracket	display contained "[);{}]\|<%\|%>"

syntax region	qcBadBlock	keepend start="{" end="}" contained containedin=qcParen,qcBracket,qcBadBlock transparent fold

"integer number, or floating point number without a dot and with "f".
syn case ignore
syn match	qcNumbers	display transparent "\<\d\|\.\d" contains=qcNumber,qcFloat,qcOctalError,qcOctal
" Same, but without octal error (for comments)
syn match	qcNumbersCom	display contained transparent "\<\d\|\.\d" contains=qcNumber,qcFloat,qcOctal
syn match	qcNumber		display contained "\d\+\(u\=l\{0,2}\|ll\=u\)\>"
"hex number
syn match	qcNumber		display contained "0x\x\+\(u\=l\{0,2}\|ll\=u\)\>"
" Flag the first zero of an octal number as something special
syn match	qcOctal		display contained "0\o\+\(u\=l\{0,2}\|ll\=u\)\>" contains=qcOctalZero
syn match	qcOctalZero	display contained "\<0"
syn match	qcFloat		display contained "\d\+f"
"floating point number, with dot, optional exponent
syn match	qcFloat		display contained "\d\+\.\d*\(e[-+]\=\d\+\)\=[fl]\="
"floating point number, starting with a dot, optional exponent
syn match	qcFloat		display contained "\.\d\+\(e[-+]\=\d\+\)\=[fl]\=\>"
"floating point number, without dot, with exponent
syn match	qcFloat		display contained "\d\+e[-+]\=\d\+[fl]\=\>"

" flag an octal number with wrong digits
syn match	qcOctalError	display contained "0\o*[89]\d*"
syn case match

if exists("klsajdfkajsdkfc_comment_strings")
  " A comment can contain qcString, qcCharacter and qcNumber.
  " But a "*/" inside a qcString in a qcComment DOES end the comment!  So we
  " need to use a special type of qcString: qcCommentString, which also ends on
  " "*/", and sees a "*" at the start of the line as comment again.
  " Unfortunately this doesn't very well work for // type of comments :-(
  syntax match	qcCommentSkip	contained "^\s*\*\($\|\s\+\)"
  syntax region qcCommentString	contained start=+L\=\\\@<!"+ skip=+\\\\\|\\"+ end=+"+ end=+\*/+me=s-1 contains=qcSpecial,qcCommentSkip
  syntax region qcComment2String	contained start=+L\=\\\@<!"+ skip=+\\\\\|\\"+ end=+"+ end="$" contains=qcSpecial
  syntax region  qcCommentL	start="//" skip="\\$" end="$" keepend contains=@qcCommentGroup,qcComment2String,qcCharacter,qcNumbersCom,qcSpaceError,@Spell
  syntax region qcComment	matchgroup=qcCommentStart start="/\*" end="\*/" contains=@qcCommentGroup,qcCommentStartError,qcCommentString,qcCharacter,qcNumbersCom,qcSpaceError,@Spell extend
else
  syn region	qcCommentL	start="//" skip="\\$" end="$" keepend contains=@qcCommentGroup,qcSpaceError,@Spell
  syn region	qcComment	matchgroup=qcCommentStart start="/\*" end="\*/" contains=@qcCommentGroup,qcCommentStartError,qcSpaceError,@Spell extend
endif
" keep a // comment separately, it terminates a preproc. conditional
syntax match	qcCommentError	display "\*/"
syntax match	qcCommentStartError display "/\*"me=e-1 contained

syn keyword	qcOperator	sizeof
syn keyword	qcType		void float vector string entity

syn keyword	qcStructure	typedef
syn keyword	qcStorageClass	static const

syn keyword     qcConstant      nil true false
syn keyword     qcConstant      __LINE__ __FILE__


syn region	qcPreCondit	start="^\s*#|#\s*\(if\|ifdef\|ifndef\|elif\)\>" skip="\\$" end="$" keepend contains=qcComment,qcCommentL,qcCppString,qcCharacter,qcCppParen,qcParenError,qcNumbers,qcCommentError,qcSpaceError
syn match	qcPreConditMatch	display "^\s*#|#\s*\(else\|endif\)\>"
syn region	qcIncluded	display contained start=+"+ skip=+\\\\\|\\"+ end=+"+
syn match	qcIncluded	display contained "<[^>]*>"
syn match	qcInclude	display "^\s*#|#\s*include\>\s*["<]" contains=qcIncluded
"syn match qcLineSkip	"\\$"
syn cluster	qcPreProcGroup	contains=qcPreCondit,qcIncluded,qcInclude,qcDefine,qcErrInParen,qcErrInBracket,qcUserLabel,qcSpecial,qcOctalZero,qcCppOutWrapper,qcCppInWrapper,@qcCppOutInGroup,qcFormat,qcNumber,qcFloat,qcOctal,qcOctalError,qcNumbersCom,qcString,qcCommentSkip,qcCommentString,qcComment2String,@qcCommentGroup,qcCommentStartError,qcParen,qcBracket,qcMulti,qcBadBlock
syn region	qcDefine		start="^\s*#|#\s*\(define\|undef\)\>" skip="\\$" end="$" keepend contains=ALLBUT,@qcPreProcGroup,@Spell
syn region	qcPreProc	start="^\s*#|#\s*\(pragma\>\|line\>\|warning\>\|warn\>\|error\>\)" skip="\\$" end="$" keepend contains=ALLBUT,@qcPreProcGroup,@Spell

" Highlight User Labels
syn cluster	qcMultiGroup	contains=qcIncluded,qcSpecial,qcCommentSkip,qcCommentString,qcComment2String,@qcCommentGroup,qcCommentStartError,qcUserCont,qcUserLabel,qcBitField,qcOctalZero,qcCppOutWrapper,qcCppInWrapper,@qcCppOutInGroup,qcFormat,qcNumber,qcFloat,qcOctal,qcOctalError,qcNumbersCom,qcCppParen,qcCppBracket,qcCppString
syn region	qcMulti		transparent start='?' skip='::' end=':' contains=ALLBUT,@qcMultiGroup,@Spell
" Avoid matching foo::bar() in C++ by requiring that the next char is not ':'
syn cluster	qcLabelGroup	contains=qcUserLabel
syn match	qcUserCont	display "^\s*\I\i*\s*:$" contains=@qcLabelGroup
syn match	qcUserCont	display ";\s*\I\i*\s*:$" contains=@qcLabelGroup
syn match	qcUserCont	display "^\s*\I\i*\s*:[^:]"me=e-1 contains=@qcLabelGroup
syn match	qcUserCont	display ";\s*\I\i*\s*:[^:]"me=e-1 contains=@qcLabelGroup

syn match	qcUserLabel	display "\I\i*" contained

" Avoid recognizing most bitfields as labels
syn match	qcBitField	display "^\s*\I\i*\s*:\s*[1-9]"me=e-1 contains=qcType
syn match	qcBitField	display ";\s*\I\i*\s*:\s*[1-9]"me=e-1 contains=qcType

" Define the default highlighting.
" Only used when an item doesn't have highlighting yet
hi def link qcFormat		qcSpecial
hi def link qcCppString		qcString
hi def link qcCommentL		qcComment
hi def link qcCommentStart	qcComment
hi def link qcLabel		Label
hi def link qcUserLabel		Label
hi def link qcConditional	Conditional
hi def link qcRepeat		Repeat
hi def link qcCharacter		Character
hi def link qcSpecialCharacter	qcSpecial
hi def link qcNumber		Number
hi def link qcOctal		Number
hi def link qcOctalZero		PreProc	 " link this to Error if you want
hi def link qcFloat		Float
hi def link qcOctalError	qcError
hi def link qcParenError	qcError
hi def link qcErrInParen	qcError
hi def link qcErrInBracket	qcError
hi def link qcCommentError	qcError
hi def link qcCommentStartError	qcError
hi def link qcSpaceError	qcError
hi def link qcSpecialError	qcError
hi def link qcCurlyError	qcError
hi def link qcOperator		Operator
hi def link qcStructure		Structure
hi def link qcStorageClass	StorageClass
hi def link qcInclude		Include
hi def link qcPreProc		PreProc
hi def link qcDefine		Macro
hi def link qcIncluded		qcString
hi def link qcError		Error
hi def link qcStatement		Statement
hi def link qcCppInWrapper	qcCppOutWrapper
hi def link qcCppOutWrapper	qcPreCondit
hi def link qcPreConditMatch	qcPreCondit
hi def link qcPreCondit		PreCondit
hi def link qcType		Type
hi def link qcConstant		Constant
hi def link qcCommentString	qcString
hi def link qcComment2String	qcString
hi def link qcCommentSkip	qcComment
hi def link qcString		String
hi def link qcComment		Comment
hi def link qcSpecial		SpecialChar
hi def link qcTodo		Todo
hi def link qcBadContinuation	Error
hi def link qcCppOutSkip	qcCppOutIf2
hi def link qcCppInElse2	qcCppOutIf2
hi def link qcCppOutIf2		qcCppOut2  " Old syntax group for #if 0 body
hi def link qcCppOut2		qcCppOut  " Old syntax group for #if of #if 0
hi def link qcCppOut		Comment

let b:current_syntax = "qc"

" vim: ts=8
