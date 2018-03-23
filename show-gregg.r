REBOL [
	Title: "Slideshow Presenter"
    Author: ["Carl Sassenrath" "Gregg Irwin"]
	Version: 1.2.1
	Date: 22-Mar-2018
]
Red []

gold: 252.181.77

;-------------------------------------------------------------------------------

if not rebol [
    if not value? 'join [
        combine: func [
        	"Merge values, modifying a if possible"
        	a "Modified if series or map"
        	b "Single value or block of values; reduced if `a` is not an object or map"
        ][
        	if all [block? :b  not object? :a  not map? :a] [b: reduce b]
        	case [
        		series? :a [append a :b]
        		map?    :a [extend a :b]
        		object? :a [make a :b]					; extend doesn't work on objects yet
        		'else      [append form :a :b]
        	]
        ]
        join: func [
        	"Concatenate/merge values"
        	a "Coerced to string if not a series, map, or object"
        	b "Single value or block of values; reduced if `a` is not an object or map"
        ][
        	if all [block? :b  not object? :a  not map? :a] [b: reduce b]
        	case [
        		series? :a [a: copy a]
        		map?    :a [a: copy a]
        		object? :a []	; form or mold?
        		'else      [a: form :a]
        	]
        	combine a b
        ]
        
    ]
    
    detab: function [
        "Converts leading tabs in a string to spaces. (tab size 4)"
    	string [any-string!] "(modified)"
    	/size
    	    sz [integer!] "Number of spaces per tab"
    	/all "Change all, not just leading"
    ][
    	sz: max 1 any [sz 4]						; size must be at least 1
    	buf: append/dup clear "    " space sz
    	parse string [
    		 BOL: some [
    			; If we see a tab, mark its position, then change it to the...ready?
    			; offset into our buffer of spaces, based on the the difference
    			; between our current position and the beginning of the line, modulo
    			; the tab size.
    			pos: change tab (skip buf remainder (offset? BOL pos) sz)
    			| lf BOL:							; Set our beginning-of-line marker
    			| if (all) to [tab | lf]			; Skip over non-tab chars
    			| space								; Spaces just move us forward in the line
    			| thru lf BOL:						; Skip to end of line and set our marker
    		 ]
    	]
    	string
    ]
    
]

;-------------------------------------------------------------------------------


;alert: func [msg] [request/ok msg]
alert: func [msg] [view compose [text (msg)]]

scan-ctx: context [

	out: []

	emit: func ['word d1] [
		if string? d1 [trim/tail d1]
		repend out [word d1]
	]

	emit-section: func [num] [repend out [to word! join "sect" num text] title: true]

	as-file: func [str] [to file! trim str]

	insert-file: func [str file /local text] [
		if file/1 = "%" [remove file]
		if not exists? file [alert reform ["Missing include file:" file] exit]
		text: read file
		insert/part str text any [find text "^/###" tail text] 
	]

	space: charset " ^-"
	chars: complement nochar: charset " ^-^/"
	text: none
	para: none
	title: none

	;--- Text Format Language:
	rules: [some parts]

	parts: [ ;here: (print here)

		newline |

		;--Document sections:
		"***" text-line (if title [alert reform ["Duplicate title:" text]] emit title text) |
		["===" | "-1-"] text-line (emit-section 1) |
		["---" | "-2-"] text-line (emit-section 2) |
		["+++" | "-3-"] text-line (emit-section 3) |
		["..." | "-4-"] text-line (emit-section 4) |
		"###" to end (emit end none) |

		;--Table sections; new row and new cell markers
		["-r-" | "=row"] (emit table-row none) |
		"-c-" (emit table-cell none) |
		"-h-" (emit table-head-cell none) |

		;--Special common notations:
		":" define opt newline (emit define reduce [text para]) |
		"*" paragraph opt newline (emit bullet para) |
		"#" paragraph opt newline (emit enum para) |
		";" paragraph |  ; comment
		"==" output (emit output trim/auto code) |

		;--Commands:
		"=image" image |
		"=url" some-chars copy para to newline newline (emit url reduce [text para]) |
		"=view" left? [some space copy text some chars | none (text: none)] (emit view text) |
		"=face" left? [some space copy text some chars | none (text: none)] (emit face text) |
		"=do" some space paragraph (if para [do para]) |
		"=include" some-chars here: (insert-file here as-file text) |
		"=file" some-chars (emit file as-file text) |
		"=options" some [
			spaces "no-indent" (emit option 'no-indent) |
			spaces "modern" (emit option 'modern) |
			spaces "view-code"
		] thru newline |
		"=toc" thru newline (emit toc none) |
		"=manual"
			spaces copy code some chars 
			copy text thru newline (emit manual reduce [code trim text]) |
		"=pad" (emit pad none) |

		;--Special sections:
		"\in" (emit indent-in none) |
		"/in" (emit indent-out none) |
		"\note" text-line (emit note-in text) |
		"/note" text-line (emit note-out none)|
		"\table" (emit table-in none) |
		"/table" (emit table-out none) |

		;--Defaults:
		example (emit code trim/auto code) |
		paragraph (either title [emit para para][emit title title: para]) |
		skip
	]

	spaces: [any space]
	some-chars: [some space copy text some chars]
	text-line: [copy text thru newline]
	paragraph: [copy para some [chars thru newline]]
	example:   [copy code some [indented | some newline indented]]
	indented:  [some space chars thru newline]
	output:    [copy code indented any ["==" copy text indented (append code text)]]
	define:    [copy text to " -" 2 skip any space paragraph]

	left?: [some space "left" (left-flag: on) | none (left-flag: off)]

	image: [
		left? any space copy text some chars (
			text: as-file text
			either left-flag [emit image reduce [text 'left]][emit image text]
		)
	]

	set 'scan-doc func [str] [
		clear out
		either rebol [
		    parse/all detab str rules
		][
		    parse detab str rules
		]
		copy out
	]
]

page-size: either find words-of system/view 'screen-face [
    system/view/screen-face/size
][
    system/view/screens/1/size
]
sect-size: page-size/x / 4 - 60 ;40
text-font-size: either page-size/x < 1000 [20][24] ;>
spacing-size: pick [2x2 6x6] page-size/x < 1000	;>
box-size:  page-size - (sect-size * 1x0) - 40x120
ex-size: to-pair reduce [box-size/x -1]

sect-faces: none
this-page: none
off-color: silver + 16 ;pewter
code: text: layo: xview: none

sections: []
layouts: []

;-- Presentation Generator:

emit: func ['style data] [repend layo [style data]]

page-template: [
	origin 8x0
	style tx text white font [shadow: 1x1] font-size text-font-size bold middle ex-size - 100x0
	style txpt vh2 white font-size text-font-size - 5
	style subttl vh1 ex-size/x left font-size text-font-size + 6 underline
	style subsub vh2 italic font-size text-font-size + 2
	style code tt black silver font [size: text-font-size - 6 style: 'bold colors: [0.0.0 0.0.80]] as-is para [origin: margin: 12x8]
	style tnt txt maroon bold
	style ex tx italic para [origin: 50x2]
	space spacing-size
	across
]

prior-face: none
color-face: func [n] [
	if n [
		pn/color: 0.60.0 pn/text: n  show pn
		if prior-face [prior-face/effect: none show prior-face]
		if prior-face: sect-faces/:n [
			prior-face/effect: [merge colorize 200.0.0]
			show prior-face
		]
	]
]

pad: func [n] [repend layo ['pad n]]

rtn: does [append layo 'return]

add-bullet: does [
	append layo [
		pad 30x0 + (0x1 * text-font-size / 3)
		image bullet effect [key 0.0.0]
		pad 0x-1 * text-font-size / 3
	]
]

either value? 'face [
    ;bullet: to-image make face [size: 15x15 edge: make edge [color: black size: 0x0] color: brick effect: [oval gradmul 1x1 255.255.255 0.0.0 oval]]
    bullet: to-image make face [size: 18x18 edge: make edge [color: black size: 1x1] color: brick effect: [gradmul 1x0 128.128.128 96.96.96 box]]
][
    bullet: to-image make face! [size: 18x18 edge: make edge [color: black size: 0x0] color: brick effect: [oval gradmul 1x1 255.255.255 0.0.0 oval]]
]

show-page: func [i /local blk shown?][
	layo: copy page-template

	either i > 0 [
		this-page: i: max 1 min length? sections i
		blk: pick sections i
	][
		blk: content
		this-page: 0
		shown?: true
		pad 0x75
		f-box/size: box-size - 1
	]
	color-face i

	foreach [type data] blk [
		switch type [
			sect1 [either shown? [break][shown?: true title-face/text: data show title-face]]
			sect2 [emit subsub data rtn]
			bullet [pad 80x0 emit txpt data rtn]
			para [pad spacing-size * 0x1 add-bullet pad spacing-size * 1x0 emit tx data rtn]
			pad [pad spacing-size * 0x5]
			image [pad 30x0 emit image data rtn]
			code [append layo compose/deep [
				indent 40
				pnl: panel (box-size) [ (load data) ]]
			]
		]
	]

	;append layo [return pad 20 box 20x2 140.0.0]
	f-box/pane: blk: layout/offset layo 0x0
	blk/color: none

	if i > 0 [f-box/size/y: -1]
	next-item

	if i = 2 [start: now/time]
	pb/data: (to-integer (now/time - start)) / duration
	show pb
]

find-item: func [y /local p f] [
	p: f-box/pane/pane
	forall p [
		f: first p
		if all [find [tx subttl subsub] f/style f/offset/y > y] [return f]
	]
	none
]

next-item: has [f n] [
	if f-box/size/y < box-size/y [
		if f: find-item f-box/size/y [n: find-item f/offset/y]
		f-box/size/y: either n [n/offset/y - 4][
			pn/color: 80.0.0
			show pn
			box-size/y
		]
		show f-box
		true
	]
]

viewpic: func [file] [
	v: view/new/options center-face layout [
		origin 0x0 space 0x0
		image file [unview/only v]
	] [no-title no-border]
]

duration: to-integer 1:10
start: now/time

;if not file: system/script/args [
;if not file: %content.txt [
	file: request-file
	if any [not file not file: file/1] [quit]
;]
if empty? file [quit]
if not exists? file [alert reform ["Error:" file "does not exist"] quit]
content: scan-doc read file modified? file

title-line: select content 'title

bdrop: to-image layout [
	size page-size
	backdrop %bkgnd.png effect [luma +15 fit blur]
	at 0x0 box page-size * 1x0 + 0x80 effect [merge gradmul 1x0 80.80.80 160.160.160]
	at 0x0 box page-size * 1x0 + 0x20 effect [merge gradmul 0x1 80.80.80 128.128.128]
]

main: layout [
	size page-size
	style title text white font [shadow: 1x1 style: 'bold size: text-font-size + 4 space: 1x0]
	style topics text font-size text-font-size - 2 bold off-color font [shadow: 1x1]
	backdrop bdrop
	across
	pad 5x5  image %boise-code-camp.jpg
	pad 0x16 image %red-logo.png
	pad 50x0 ;image %reb-logo.gif effect [invert]
	pad 40x4
	title-face: title title-line gold box-size/x return
	pad 0x20
	tl: topics sect-size
	f-box: box box-size
	key keycode [up left page-up #"^(back)"] [show-page this-page - 1]
	key keycode [page-down] [show-page this-page + 1]
	key keycode [down right #" "] [
		if not next-item [show-page this-page + 1]
	]
	key escape [quit]
	at page-size * 0x1 + 20x-40
	pn: text center silver font-size 10 "000"
	pad 0x4
	pb: progress 120x8
]

;-- Index to all section start points:
forskip content 2 [if content/1 = 'sect1 [append/only sections content]]
content: head content

remove find main/pane tl
tl/user-data: 0
sect-faces: tail main/pane
xy: tl/offset
tl/action: func [face value] [show-page face/user-data]

foreach [type data] content [
	if type = 'sect1 [
		append main/pane tl: make-face tl
		tl/text: data
		tl/offset: xy
		tl/font: make tl/font []
		tl/user-data: tl/user-data + 1
		xy: xy + (0x1 * tl/size/y)
	]
]

show-page 0
view/offset main 0x0
