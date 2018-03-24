Red [
	author:  "Gregg Irwin"
	title:   "Leggo Block Playchain"
	purpose: "Boise Code Camp 2018 Demo"
]

; The worst thing about using Red to write a blockchain demo is that Red
; has a native datatype called a block, which has nothing to do with 
; blockchain blocks. We could use blocks for blocks, but you're probably
; all more familiar with objects than blocks, so I'm going to use objects
; for blocks, rather than blocks, but I will use a block for the entire
; chain of blocks...er...objects.

; Here's all the information we need for each blockchain block object.
leggo-block-proto: object [
	index:       ; integer!					The block number; the genesis block being #1
	timestamp:   ; date!					When the block was created
	data:        ; binary! | any-type!  	The block contents/body
	hash:        ; binary!					The SHA256 hash of 'data
	prev-hash:   ; binary!					The hash from the previous block in the chain
		none     ; 							Initial value for all words
]

;-------------------------------------------------------------------------------

show-hash-calc?: yes	; for demo purposes, let us turn off hash output at times


calc-hash: function [
	"Calculate the hash for a block, using its contents and an increasing nonce"
	index [integer!] 
	stamp [date!] 
	data 
	prev-hash [binary!] "Hash of the previous block in the chain"
][
	hash: clear #{}
	nonce: 0

    while [not is-hash-valid? hash][
    	hash: checksum rejoin [index stamp data prev-hash nonce] 'sha256
		nonce: nonce + 1
    ]
    
    if show-hash-calc? [
    	print [
    		"CALC-HASH"
    		tab "Index:" index
    		tab "Nonce:" pad/left nonce 5
    		tab "Hash:"  mold form-hash/short hash
    	]
    ]

    hash
]

calc-hash-for-block: func [
	"Calc-hash wrapper, so we can pass just one arg"
	blk [object!]
][
	calc-hash blk/index blk/timestamp blk/data blk/prev-hash
]

dump-chain: does [
	print "^/Chain contents:^/"
	print "#    Timestamp        Hash          Data"
	foreach blk main-chain [
		print [blk/index '| pad blk/timestamp/time 12 '| form-hash/short blk/hash '| mold blk/data]
	]
	print ""
]

form-hash: func [
	"Convert binary! hash values to strings for display"
	hash [binary!]
	/short "Use 0000...FFFF format"
][
	hash: enbase/base hash 16
	either short [
		; /short is a bit tricky as each byte is now 2 hex chars,
		; so to replace 28 of them, we have to change 56 pieces.
		;head change/part at hash 5 "..." 56
		; This is clearer, though less efficient
		rejoin [take/part hash 4 "..." take/part/last hash 4]
	][hash]
]

is-block-valid?: function [block prev-block][
	msg: copy ""
	emit: func [str][append msg str]

	if block/index <> (prev-block/index + 1) [
        emit "Bad block index. "
    ]
	if block/prev-hash <> prev-block/hash [
        emit "Bad block previous hash. "
    ]
	if block/hash <> calc-hash-for-block block [
        emit "Bad block hash. "
    ]
	if not is-hash-valid? block/hash [
        emit "Invalid block hash. "
    ]

    either empty? msg [true][
    	print [msg ">> Block: " mold block]
    	false
    ]
]

is-hash-valid?: func [hash [binary!]][
	all [
		32 = length? hash
		0 = first hash					; first on binary! returns integer, not binary!
		;find/match hash #{0000}		; matching longer prefixes means more work
		;find/match hash #{00000000}	; ...or MUCH more work
	]
]

is-main-chain-valid?: does [
	to logic! all [
		genesis-block = first main-chain
		(
			chain: next main-chain
			forall chain [
				if not is-block-valid? chain/1 chain/-1 [return false]
			]
			true
		)
	]
]

;-------------------------------------------------------------------------------

emit-block: func [
	"Add a block to the main chain; returns true if the block was added, false otherwise"
	blk [object!]
	/local res
][
	show-hash-calc?: no										; disable hash-calc output
	res: either is-block-valid? blk last main-chain [
		append main-chain blk
		yes
	][
		print "I'm not going to emit an invalid block."
		no
	]
	show-hash-calc?: yes									; re-enable hash-calc output
	res
]

add-new-block: function [data][
    last-blk: last main-chain								; current last block in the global blockchain
    index: last-blk/index + 1
    stamp: now/precise
    emit-block object compose [
		index:     (index)
		timestamp: (stamp)
		data:      (data)
		hash:      (calc-hash index stamp data last-blk/hash)
		prev-hash: (last-blk/hash)
    ]
]

;last-block: does [last main-chain]

;-------------------------------------------------------------------------------

genesis-block: object [
    index:     1
    timestamp: now/precise
    data:      "IN THE BEGINNING..."
    prev-hash: calc-hash 0 1-Jan-0001 "" #{}			; 0 index, fixed stamp, no data, empty prev-hash
    hash:      calc-hash index timestamp data prev-hash
]

main-chain: reduce [genesis-block]						; Global blockchain data is stored here

add-new-block "This is my data"
add-new-block "And this is another block"
add-new-block "And yet another"

show-hash-calc?: no
print ["^/Is the chain valid? " pick [Yes No] is-main-chain-valid?]

dump-chain

;show-hash-calc?: yes
