Red [
	author: "Gregg Irwin"
	purpose: {
		Boise Code Camp 2018 Demo
		
		Define a dialect to specify contact actions [who what when where how].
		
		e.g. send someone a message, or set a reminder for yourself, about some
		kind of contact related action to take, like sending an email, posting
		a comment on the net, or calling someone on the phone. And you want to
		be able to see what's coming up in some kind of list.
	}
	notes: {
		Starting out: Describe your language
		
		    What do you want to express?
		    
		    How do you want to say it?
		    
		    What are the things you need to talk about?
		    
		    How simple can you keep it?
		    
		    What are your anchors (e.g. keywords and delimiters)
		    
		Write examples before you write any code.
		
		Play with different ideas before trying to make any of it work.
	}		
]

examples: [
	call @Bob at 12:00 about deadlines .
	email glt@walt.com on Monday regarding "TopDog contract" .
	post %news.txt to https://my-blog-host.dom/news on 24-Mar-2018/09:30 .
;	chat on gitter .
;	psst %news.txt to https://my-blog-host.dom/news on 24-Mar-2018/09:30 .
]

;-------------------------------------------------------------------------------

gitter: https://gitter.im/red/red
reddit: https://www.reddit.com/r/redlang/

;-------------------------------------------------------------------------------

set [how who when what where] none

; The '= suffix sigil is just a BNF-like convention I use sometimes
; to denote parse rules.

how=: [set how ['call | 'email | 'post | 'chat]]

who=: [set who [email! | file!]]

weekday=: [
	'mon | 'tue | 'wed | 'thu | 'fri | 'sat | 'sun
	| 'Monday | 'Tuesday | 'Wednesday | 'Thursday | 'Friday | 'Saturday | 'Sunday
]
when=: [
	'on set when [date! | weekday=]
	| 'at set when time!
]

what=: [
	['about | 'regarding] set what [word! | string!]
]

where=: [
	['to set where url!]
	| p: 'on set where ['gitter | 'reddit]
]

main-rule: [
	some [
		(set [how who when what where] none)
		how= [who= when= what= | opt who= where= opt when=] '. (
			switch how [
				call  [print [when tab "Don't forget to call" who]]		; fire up Skype?
				email [print [when tab "Email" who "about" what]]		; send who what
				post  [print [when "I'll post" mold who  "to" where]]	; write where who
				chat  [browse get where]
			]
		)
	]
]

res: parse examples main-rule

print [newline "Was the input valid?  " pick [Yes No] res]
