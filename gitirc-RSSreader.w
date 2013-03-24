@s list int
@s std int
@s string int
@s vector int
@s iterator int
@ @(gitirc-RSSreader.h@>=
#ifndef GITIRC_RSSREADER_H
#define GITIRC_RSSREADER_H
#include <string>
#include <vector>
#include <list>
#include <memory>
class RSSreader {
public:
	enum RSS_token_type {
		opening = 0, value, node_type, ending
	};
	struct rss_node {
		std::list<std::shared_ptr<rss_node>> children;
		rss_node* parent;
		std::string name,attributes,value;
		~rss_node() {}
		rss_node()@+:@+parent(0) {}
		rss_node(const std::string&s)@+:@+parent(0),name(s) {}
	};
	struct rss_stack_node {
		std::string s;
		std::shared_ptr<rss_node> rn;
		RSS_token_type t;
		rss_stack_node(const std::string& p,const RSS_token_type& q) :
			s(p), t(q) {}
		rss_stack_node(std::shared_ptr<rss_node>&& r)@+:@+s(r->name),
			rn(std::move(r)), t(node_type) {}
		rss_stack_node(const rss_stack_node&) = delete;
		rss_stack_node& operator=(rss_stack_node&& r)
		{
			if(&r == this) return *this;
			s = std::move(r.s);
			t = r.t;
			rn = std::move(r.rn);	
			return *this;
		}
		rss_stack_node(rss_stack_node&& r) : s(std::move(r.s)), rn(std::move(r.rn)), t(r.t)
			{}
	};
	bool insert(const char ch);
	RSSreader()@+:@+state(0) {}
	std::vector<rss_stack_node>& st()@+{@+return stck;@+}
	~RSSreader() {}
private:
	bool shift_and_reduce();
	std::vector<rss_stack_node> stck;
	std::string current;
	int state;
};
#endif // |GITIRC_RSSREADER_H|
@ @c
#include "gitirc-RSSreader.h"
#include <unistd.h>
bool RSSreader::insert(const char ch)
{
	switch(state) {
		case 0: @<Handle state 0 in parser@>@;@+break;
		case 1: @<Handle state 1 in parser@>@;@+break;
		case 2: @<Handle state 2 in parser@>@;@+break;
		case 3: @<Handle state 3 in parser@>@;@+break;
		case 4: @<Handle state 4 in parser@>@;@+break;
		case 5: @<Handle state 5 in parser@>@;@+break;
		case 6: @<Handle state 6 in parser@>@;@+break;
		case 7: @<Handle state 7 in parser@>@;@+break;
		case 8: @<Handle state 8 in parser@>@;@+break;
		case 9: @<Handle state 9 in parser@>@;@+break;
		default:
			return false; break;
	}
	return true;
}
@ @<Handle state 0 in parser@>=
current.clear();
if(ch == '<')
	state = 1;
@ @<Handle state 1 in parser@>=
if(ch == '?' || ch == '>')
	state = 0;
else if(!isspace(ch)) {
	state = 2;
	current += ch;
}
@ @<Handle state 2 in parser@>=
if(isspace(ch))
	state = 3;
else if(ch == '>') {
	state = 4;
	stck.push_back(rss_stack_node(current,opening));
	current.clear();
} else current += ch;
@ @<Handle state 3 in parser@>=
if(ch == '>') {
	state = 4;
	stck.push_back(rss_stack_node(current,opening));
	current.clear();
}
@ @<Handle state 4 in parser@>=
if(ch == '<')
	state = 5;
else if(!isspace(ch)) {
	state = 6;
	current += ch;
}
@ @<Handle state 5 in parser@>=
if(ch == '/')
	state = 7;
else if(!isspace(ch)){
	state = 2;
	current += ch;
}
@ @<Handle state 6 in parser@>=
if(ch == '<') {
	state = 8;
	stck.push_back(rss_stack_node(current,value));
	current.clear();
} else current += ch;
@ @<Handle state 7 in parser@>=
if(ch == '>'){
	state = 4;
	stck.push_back(rss_stack_node(current,ending));
	current.clear();
	if(!shift_and_reduce())
		return false;
}
else if(!isspace(ch))
	current += ch;
else state = 9;
@ @<Handle state 8 in parser@>=
if(!isspace(ch) && ch != '/') return false;
else state = 7;
@ @<Handle state 9 in parser@>=
if(ch == '>'){
	state = 4;
	stck.push_back(rss_stack_node(current,ending));
	current.clear();
	if(!shift_and_reduce())
		return false;
}
@ @c
bool RSSreader::shift_and_reduce()
{
	auto q = stck.end();
	int stack_state = 0;
	@<First, check that we have a |ending| node on top@>@;
	auto fi = q;
	@<Two more sanity checks on our stack@>@;
	std::shared_ptr<rss_node> nnode(new rss_node(fi->s));
	while(++fi != stck.end())
		if(fi->t == node_type)
			@<Iterate over nodes@>@;
		else if(fi->t == value)
			@<Iterate over values@>@;
		else if(fi->t == ending)
			@<Tie up everything, we are at the end@>@;
	return true;
}
@ @<Tie up everything, we are at the end@>={
	if(++fi != stck.end())
		return false;
	stck.erase(q,stck.end());
	stck.push_back(rss_stack_node(std::move(nnode)));
	break;
}
@ There should be a single line between the opening and the ending nodes here.
@<Iterate over values@>={
	if(stack_state != 0) return false;
	stack_state = 2; // So if we enter here again, it is a problem
	nnode->value = fi->s;
}
@ The node here is a list of nodes. We set the parent field.
We make sure no other type of nodes are on the stack here.
@<Iterate over nodes@>={
	if(stack_state != 0 && stack_state != 1) return false;
	stack_state = 1;
	fi->rn->parent = nnode.get();
	nnode->children.push_back(std::move(fi->rn));
}
@ First, we want to make sure we are at an |opening| node.  Then we want to
make sure the names match.
@<Two more sanity checks on our stack@>=
if(fi->t != opening)
	::_exit(1);
if(stck.empty() || fi->s != stck.back().s)
	return false;
@ If we do not have an |ending| node, there is definitely something wrong.
@<First, check that we have a |ending| node on top@>=
--q;
if(q->t != ending)
	return false;
while(q >= stck.begin()){
	if(q->t == opening)
		break;
	--q;
}
