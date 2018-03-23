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
	
]

examples: [
	call @Bob at 12:00 about deadlines .
	email dave@vop.com on Monday regarding "TopDog contract" .
	post %news.txt to https://my-blog-host.dom/news on 24-Mar-2018/09:30 .
	chat on gitter .
]

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
	;(print [tab '==when when])
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
		how= [who= when= what= | opt who= where= opt when=] '. pos: (
		;how= [opt who= where= opt when= | who= when= what=] '. (
			;print [how who when what where]
			;print mold pos
			switch how [
				call  [print [when tab "Don't forget to call" who]]
				email [print [when tab "Email" who "about" what]]
				post  [print [when "I'll post" mold who  "to" where]]
				chat  [browse get where]
			]
		)
	]
]

print parse examples main-rule
