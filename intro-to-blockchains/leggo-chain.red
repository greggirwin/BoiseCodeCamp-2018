Red []

chain: copy []	; Global blockchain data is stored here

calc-hash: func [
	index [integer!] 
	stamp [date!] 
	data 
	prev-hash [binary!]
][
	checksum rejoin [index stamp data prev-hash] 'sha256
]


;context [
;	genesis-block: reduce [
;	    1							; index
;	    now/precise					; timestamp
;	    "IN THE BEGINNING..."		; data
;	    #{9F13429F1790F34E7E5A94D1EB68821FDAD39F3DED46CB05C3478941DC7C17EE}	; sha256 of "IN THE BEGINNING..." 
;	    calc-hash 1 now/precise data last-blk/hash
;	    #{E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855}	; sha256 of ""
;	]
;]

genesis-block: object [
    index:     1
    timestamp: now/precise
    data:      "IN THE BEGINNING..."
    prev-hash: checksum "" 'sha256
    hash:      calc-hash index timestamp data prev-hash
    ;calc-hash 1 now/precise data last-blk/hash
    ;#{9F13429F1790F34E7E5A94D1EB68821FDAD39F3DED46CB05C3478941DC7C17EE}	; sha256 of "IN THE BEGINNING..." 
    
]

append chain genesis-block


; index, timestamp, data, hash and previous hash.

leggo-block-proto: object [
	index:       ; integer!					The block number; the genesis block being #1
	timestamp:   ; date!					When the block was created
	data:        ; binary! | any-type! ?	The block contents/body
	hash:        ; binary!					Contains the SHA256 hash of 'data
	prev-hash:   ; binary!					Contains the hash from the previous block-proto
		none     ; 							Initial value for all words
]
block-proto-keys: words-of leggo-block-proto

leggo-block: [
	index:     #[none]	; integer!
	timestamp: #[none]	; date!
	data:      #[none]	; binary! | any-type! ?
	hash:      #[none]	; binary!
	prev-hash: #[none]	; binary!
]
block-keys: extract leggo-block 2


mk-blk: function [/with spec [block!]][
	res: copy leggo-block
	foreach [word val] spec [
		if find block-keys word [
			res/:word: val
		]
	]
	res
]

make-next-block: function [data][
    last-blk: last chain			; last block in the global blockchain
    index: last-blk/index + 1
    stamp: now/precise
    mk-blk/with compose [
		index:     (index)
		timestamp: (stamp)
		data:      (data)
		hash:      (calc-hash index stamp data last-blk/hash)
		prev-hash: (last-blk/hash)
    ]
]

make-genesis-block: does [
	
]

hash-block: func [block [block!] "Leggo block"][
]


valid-hash?: func [value [binary!]][
	all [
		32 = length? value
	]
]

get-prev-hash: func [] [
	
]

add-new-block: func [block [block!] "Leggo block"][
	
]

;-------------------------------------------------------------------------------

calc-hash-for-block: func [blk [object!]][
	calc-hash blk/index blk/timestamp blk/data blk/prev-hash
]

is-block-valid?: function [block prev-block][
	msg: copy ""
	if block/index <> (prev-block/index + 1) [
        append msg "Bad block index. "
    ]
	if block/prev-hash <> prev-block/hash [
        append msg "Bad block previous hash. "
    ]
	if block/hash <> calc-hash-for-block block [
        append msg "Bad block hash. "
    ]
    either empty? msg [true][
    	print [msg ">> Block: " mold block]
    	false
    ]
]

