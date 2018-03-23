Red [
	purpose: {
		Define a dialect to specify contact actions [who what when how].
		
		e.g. send someone a message, or set a reminder for yourself, about some
		kind of contact related action to take, like sending an email, posting
		a comment on the net, or calling someone on the phone. And you want to
		be able to see what's coming up in some kind of list.
	}
	
]

examples: [
	call Bob at 12:00 about deadlines .
	email dave@vop.com on Monday regarding "TopDog contract" .
	post %news.txt to https://my-blog-host.dom/news on 24-Mar-2018/09:30 .
	chat on gitter
]

gitter: https://gitter.im/red/red

;-------------------------------------------------------------------------------

set [who what when how] none

who=: [set who [word! | email! | file!]]

what=: [['about | 'regarding] set what [word! | string!]]

weekday=: [
	'mon | 'tue | 'wed | 'thu | 'fri | 'sat | 'sun
	| 'Monday | 'Tuesday | 'Wednesday | 'Thursday | 'Friday | 'Saturday | 'Sunday
]
when=: [['on | 'at] set when [date! | time!]]

how=: [set how ['call | 'email | 'post | 'chat]]

where=: ['on ['gitter | 'reddit]]

