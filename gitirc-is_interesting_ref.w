@s std int
@s string int
@ @(gitirc-is_interesting_ref.h@>=
#ifndef GITIRC_IS_INTERESTING_REF_H
#define GITIRC_IS_INTERESTING_REF_H
#include <string>
int is_interesting_ref(const std::string& s);
#endif
@ This whole thing should be marked as an HTCondor hack.
@c
#include <string>
bool is_interesting_ref(const std::string& s)
{
	bool ret = (s == "master");
	int state=0;
	auto sit = s.begin();
	while(!ret) {
		@<Iterate over the ref name@>@;
		if(sit == s.end())
			break;
		++sit;
	}
#if 0
	std::cerr << "matches(" << s << ") returning " << ret << std::endl;
#endif
	return ret;
}
@ @<Iterate over the ref name@>=
#if 0
std::cerr << "state = " << state << ", *sit = " << *sit << std::endl;
#endif
switch(state) {
case 0: @<Handle state 0@>@;@+break;
case 1: @<Handle state 1@>@;@+break;
case 2: @<Handle state 2@>@;@+break;
case 3: @<Handle state 3@>@;@+break;
case 4: @<Handle state 4@>@;@+break;
case 5: @<Handle state 5@>@;@+break;
case 6: @<Handle state 6@>@;@+break;
case 7: @<Handle state 7@>@;@+break;
default: break;
}
@ @<Handle state 0@>=
if(*sit != 'V') sit = s.end();
state = 1;
@ @<Handle state 1@>=
if(!isdigit(*sit)) sit = s.end();
state = 2;
@ @<Handle state 2@>=
if(*sit == '_') state = 3;
else if(!isdigit(*sit)) sit = s.end();
@ @<Handle state 3@>=
if(!isdigit(*sit)) sit = s.end();
state = 4;
@ @<Handle state 4@>=
if(*sit == '_') state = 5;
else if(*sit == '-') state = 7;
else if(!isdigit(*sit)) sit = s.end();
@ @<Handle state 5@>=
if(!isdigit(*sit)) sit = s.end();
state = 6;
@ @<Handle state 6@>=
if(*sit == '-') state = 7;
else if(!isdigit(*sit)) sit = s.end();
@ @<Handle state 7@>={
	std::string st(sit,s.end());
#if 0
	std::cerr << "st = " << st << std::endl;
#endif
	ret = (st == "branch");
}
sit = s.end();
