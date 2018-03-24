Red [
	title: "Leggo Block Playchain"
]


leggo-block-proto: object [
	index:       ; integer!					The block number; the genesis block being #1
	timestamp:   ; date!					When the block was created
	data:        ; binary! | any-type! ?	The block contents/body
	hash:        ; binary!					Contains the SHA256 hash of 'data
	prev-hash:   ; binary!					Contains the hash from the previous block-proto
		none     ; 							Initial value for all words
]
;block-proto-keys: words-of leggo-block-proto

;-------------------------------------------------------------------------------

show-hash-calc?: yes

calc-hash: function [
	index [integer!] 
	stamp [date!] 
	data 
	prev-hash [binary!]
][
	hash: clear #{}
	nonce: 0

    while [not is-hash-valid? hash][
    	hash: checksum rejoin [index stamp data prev-hash nonce] 'sha256
		nonce: nonce + 1
    ]
    
    if show-hash-calc? [
    	print ["CALC-HASH" tab "Index:" index "Nonce:" nonce "Hash:" mold form-hash/short hash]
    ]

    hash
]

calc-hash-for-block: func [
	"calc-hash wrapper, so we can pass just on arg"
	blk [object!]
][
	calc-hash blk/index blk/timestamp blk/data blk/prev-hash
]

dump-chain: does [
	print "^/Chain contents:"
	print "#  Timestamp      Hash         Data"
	foreach blk main-chain [
		print [blk/index blk/timestamp/time form-hash/short blk/hash mold blk/data]
	]
	print ""
]

form-hash: func [
	"Convert binary! hash values to strings for display"
	hash [binary!]
	/short "Use 0000...FFFF format"
][
	hash: enbase/base hash 16
	; /short is a bit tricky as each byte is now 2 hex chars,
	; so to replace 28 of them, we have to change 56 pieces.
	either short [head change/part at hash 5 "..." 56][hash]
]

is-block-valid?: function [block prev-block][
	msg: copy ""
	;print [mold block mold prev-block]
	if block/index <> (prev-block/index + 1) [
        append msg "Bad block index. "
    ]
	if block/prev-hash <> prev-block/hash [
        append msg "Bad block previous hash. "
    ]
	if block/hash <> calc-hash-for-block block [
        append msg "Bad block hash. "
    ]
	if not is-hash-valid? block/hash [
        append msg "Invalid block hash. "
    ]
    either empty? msg [true][
    	print [msg ">> Block: " mold block]
    	false
    ]
]

is-main-chain-valid?: does [
	to logic! all [
		genesis-block = first main-chain
		chain: next main-chain
		forall chain [
			if not is-block-valid? chain/1 chain/-1 [return false]
			true
		]
	]
]

is-hash-valid?: func [value [binary!]][
	all [
		32 = length? value
		0 = first value					; first on binary! returns integer, not binary!
		;find/match value #{0000}		; matching longer prefixes means much more work
		;find/match value #{00000000}
	]
]

;-------------------------------------------------------------------------------

emit-block: func [blk [object!]][
	either is-block-valid? blk last main-chain [
		append main-chain blk
	][
		print "I'm not going to emit an invalid block."
	]
]

add-new-block: function [data][
    last-blk: last main-chain								; last block in the global blockchain
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

last-block: does [last main-chain]

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
