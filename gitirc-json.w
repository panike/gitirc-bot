@i c++lib
@ This is a JSON parser.
@c
@h
@<Header inclusions@>@;
@<Global variable declarations@>@;
@ @(json.h@>=
#ifndef _PANIKE_JSON_H
#define _PANIKE_JSON_H
#include <string>
#include <map>
#include <vector>
#include <iostream>
#include <memory>
namespace JSON {
class json_node {
public:
	@<Declare helper types for |json_node|@>@;
	@<Public member functions for |json_node|@>@;
private:
	@<Private member functions for |json_node|@>@;
	@<Private data for |json_node|@>@;
};
}
#endif
@ @<Declare helper types for |json_node|@>=
enum Type { json_string, number, object, array, json_bool, json_null };
@ @<Public member functions for |json_node|@>=
static std::shared_ptr<json_node> parse(std::string::const_iterator begin,
	const std::string::const_iterator end,
	std::string::const_iterator* term);
@ @<Public member functions for |json_node|@>=
const json_node* get(const std::string& name) const;
@ @<Public member functions for |json_node|@>=
const json_node& operator[](const std::string& name) const;
@ @<Public member functions for |json_node|@>=
const std::vector<std::shared_ptr<json_node>>& get_array() const { return obj_array; }
@ @<Public member functions for |json_node|@>=
const std::map<std::string,std::shared_ptr<json_node>>& get_object() const { return obj_data; }
@ @<Public member functions for |json_node|@>=
json_node* get(unsigned int) const;
@ @<Public member functions for |json_node|@>=
const json_node& operator[](unsigned int) const;
@ @<Public member functions for |json_node|@>=
const std::string& get() const;
@ @<Public member functions for |json_node|@>=
bool get_bool() const { return bdata; }
@ @<Public member functions for |json_node|@>=
Type what_type() const { return type; }
@ @<Public member functions for |json_node|@>=
bool is_null() const { return type == json_null; }
@ @<Public member functions for |json_node|@>=
~json_node() {}
@ @<Public member functions for |json_node|@>=
json_node() : type(json_null), bdata(false), parent(0) {}
@ @<Public member functions for |json_node|@>=
std::ostream& print(std::ostream& os, const char* prefix) const;
@ @<Private member functions for |json_node|@>=
static std::string parse_string(std::string::const_iterator begin,
	const std::string::const_iterator end,
	std::string::const_iterator* term);
@ @<Private member functions for |json_node|@>=
static std::string parse_number(std::string::const_iterator begin,
	const std::string::const_iterator end,
	std::string::const_iterator* term);
@ @<Private member functions for |json_node|@>=
static std::shared_ptr<json_node> parse_lit(std::string::const_iterator begin,
	const std::string::const_iterator end,
	std::string::const_iterator* term);
@ @<Private member functions for |json_node|@>=
static std::shared_ptr<json_node> parse_value(std::string::const_iterator begin,
	const std::string::const_iterator end,
	std::string::const_iterator* term);
@ @<Private member functions for |json_node|@>=
static bool is_whitespace(char ch);
@ @<Private data for |json_node|@>=
Type type;
@ @<Private data for |json_node|@>=
std::map<std::string,std::shared_ptr<json_node>> obj_data;
@ @<Private data for |json_node|@>=
std::vector<std::shared_ptr<json_node>> obj_array;
@ @<Private data for |json_node|@>=
static const std::string nulls;
@ @<Private data for |json_node|@>=
std::string data;
@ @<Private data for |json_node|@>=
bool bdata;
@ @<Private data for |json_node|@>=
json_node* parent;
static json_node def;
@ @c
JSON::json_node JSON::json_node::def;
@ @c
bool JSON::json_node::is_whitespace(char ch)
{
	return (ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n');
}
@ @<Global variable declarations@>=
const std::string JSON::json_node::nulls = "";
@ @c
const JSON::json_node* JSON::json_node::get(const std::string& name) const
{
	auto p = obj_data.find(name);
	return ((p == obj_data.end())?0:p->second.get());
}
@ @c
JSON::json_node* JSON::json_node::get(unsigned int idx) const
{
	if( idx >= obj_array.size()) return 0;
	return obj_array[idx].get();
}
@ @c
const std::string& JSON::json_node::get() const
{
	if(type == json_string || type == number) return data;
	return nulls;
}
@ @c
std::shared_ptr<JSON::json_node> JSON::json_node::parse(std::string::const_iterator begin,
		const std::string::const_iterator end,
		std::string::const_iterator* term)
{
#if 0
	std::cerr << "entering " << __PRETTY_FUNCTION__ << std::endl;
#endif
	int state = 0;
	std::string name;
	std::shared_ptr<json_node> child;
	std::string::const_iterator end_string;
	std::shared_ptr<json_node> ret(new json_node);
	if(ret) ret->type = object;
	while(ret && begin != end) {
#if 0
		std::cerr << "begin points to " << *begin << ", state = " << state << std::endl;
#endif
		if(is_whitespace(*begin)) {
			++begin;
			continue;
		}
		switch(state) {
		case 0: @<Handle case 0 in |json_node::parse|@>@;@+break;
		case 1: @<Handle case 1 in |json_node::parse|@>@;@+break;
		case 2: @<Handle case 2 in |json_node::parse|@>@;@+break;
		case 3: @<Handle case 3 in |json_node::parse|@>@;@+break;
		case 4: @<Handle case 4 in |json_node::parse|@>@;@+break;
		case 5: @<Handle case 5 in |json_node::parse|@>@;@+break;
		case 6: @<Handle case 6 in |json_node::parse|@>@;@+break;
		default: ret = std::shared_ptr<json_node>(); break;
		}
	}
	return ret;
}
@ @<Handle case 0 in |json_node::parse|@>=
if(*begin == '{') {
	++begin;
	state = 1;
}@+else if(*begin == '[') {
	++begin;
	ret->type = array;
	state = 5;
}@+else state = -1;
@ @<Handle case 1 in |json_node::parse|@>=
if(*begin == '"') {
	name = parse_string(begin,end,&end_string);
#if 0
	std::cerr << "name = " << name << std::endl;
#endif
	if(end_string == end) state = -1;
	else {
		state = 2;
		begin = end_string;
	}
}@+else if(*begin == '}') {
	++begin;
	*term = begin;
	begin = end;
}
@ @<Handle case 2 in |json_node::parse|@>=
if(*begin == ':') {
	++begin;
	state = 3;
}@+else state = -1;
@ @<Handle case 3 in |json_node::parse|@>=
child = parse_value(begin,end,&end_string);
if(!child) {
#if 0
	std::cerr << "child was null" << std::endl;
#endif
	state = -1;
}@+else {
	child->parent = ret.get();
	auto pp = ret->obj_data.insert(make_pair(name,child));
	if(!pp.second) state = -1;
	else {
		begin = end_string;
		state = 4;
	}
}
@ @<Handle case 4 in |json_node::parse|@>=
if(*begin == ',') {
	++begin;
	state = 1;
}@+else if(*begin == '}') {
	++begin;
	*term = begin;
	begin = end;
}@+else state = -1;
@ @<Handle case 5 in |json_node::parse|@>=
if(*begin == ']') {
	++begin;
	*term = begin;
	begin = end;
}@+else {
	child = parse_value(begin,end,&end_string);
	if(child) {
		begin = end_string;
		state = 6;
		child->parent = ret.get();
		ret->obj_array.push_back(std::move(child));
	}@+else state = -1;
}
@ @<Handle case 6 in |json_node::parse|@>=
if(*begin == ',') {
	++begin;
	state = 5;
}@+else if(*begin == ']') {
	++begin;
	*term = begin;
	begin = end;
}
@ @<Clear out whitespace@>=
while(begin != end && is_whitespace(*begin)) {
	++begin;
}
@ @c
std::shared_ptr<JSON::json_node> JSON::json_node::parse_value(std::string::const_iterator begin,
		const std::string::const_iterator end,
		std::string::const_iterator* term)
{
#if 0
	std::cerr << "entering " << __PRETTY_FUNCTION__ << std::endl;
#endif
	@<Clear out whitespace@>@;
	if(begin == end) {
		*term = end;
		return std::shared_ptr<json_node>();
	}
	std::shared_ptr<json_node> ret;
	switch(*begin) {
		@<Key off of first character@>@;
		default: *term = end; return std::shared_ptr<json_node>();break;
	}
}
@ @<Key off of first character@>=
case '{': case '[': return parse(begin,end,term);@+break;
@ @<Key off of first character@>=
case '"': ret = std::shared_ptr<json_node>(new json_node);
if(!ret) {
	*term = end;
	return std::shared_ptr<json_node>();
}
ret->type = json_string;
ret->data = parse_string(begin,end,term);
return ret;
break;
@ @<Key off of first character@>=
case 't': case 'f': case 'n': return parse_lit(begin,end,term); break;
@ @<Key off of first character@>=
case '0': case '1': case '2': case '3': case '4':
case '5': case '6': case '7': case '8': case '9':
case '-':
ret = std::shared_ptr<json_node>(new json_node);
if(!ret) {
	*term = end;
	return std::shared_ptr<json_node>();
}
ret->type = number;
ret->data = parse_number(begin,end,term);
return ret;
break;
@ @c
std::string JSON::json_node::parse_string(std::string::const_iterator begin,
		const std::string::const_iterator end,
		std::string::const_iterator* term)
{
	int state = 0;
	std::string ret;
	if(*begin != '"') return ret;
	++begin;
	@<Search for next \." character, taking escapes into account@>@;
	if(*begin != '"' || state != 0) ret.clear();
	else *term = ++begin;
	return ret;
}
@ @<Search for next \." character, taking escapes into account@>=
while(begin != end && (*begin != '"' || state == 1)) {
	switch(state){
		case 0: if(*begin == '\\') state = 1;
			else ret.append(1,*begin); break;
		case 1: @<Escape characters in JSON must be handled@>@;@+break;
		default: ret.clear(); return ret; break;
	}
	++begin;
}
@ @<Escape characters in JSON must be handled@>=
switch(*begin) {
case 'b': ret.append(1,'\b');@+break;
case 'f': ret.append(1,'\f');@+break;
case 'n': ret.append(1,'\n');@+break;
case 'r': ret.append(1,'\r');@+break;
case 't': ret.append(1,'\t');@+break;
case 'u': ret.append(1,'\\');ret.append(1,'u');@+break;
default: ret.append(1,*begin); break;
}
state = 0;
@ @<Assign the type of literal we are looking at@>=
switch(*begin) {
	case 't': case 'f': ret->type = json_bool; break;
	case 'n': ret->type = json_null; break;
	default: break;
}
@ @c
std::shared_ptr<JSON::json_node> JSON::json_node::parse_lit(std::string::const_iterator begin,
		const std::string::const_iterator end,
		std::string::const_iterator* term)
{
#if 0
	std::cerr << "entering " << __PRETTY_FUNCTION__ << std::endl;
#endif
	std::shared_ptr<json_node> ret(new json_node);
	if(!ret) return ret;
	@<Assign the type of literal we are looking at@>@;
	std::string::const_iterator pp;
	std::string s;
	switch(ret->type) {
	case json_bool: @<Expect literal \.{"true"} or \.{"false"}@>@;@+break;
	case json_null: @<Expect literal \.{"null"}@>@;@+break;
	default:
		ret = std::shared_ptr<json_node>();
		break;
	}
	return std::shared_ptr<json_node>();
}
@ @<Expect literal \.{"true"} or \.{"false"}@>=
pp = std::find(begin,end,'e');
if(pp == end) {
	*term = end;
	return std::shared_ptr<json_node>();
}
*term = ++pp;
s.assign(begin,pp);
if(s == "true") ret->bdata = true;
else if(s == "false") ret->bdata = false;
else ret = std::shared_ptr<json_node>();
@ @<Expect literal \.{"null"}@>=
pp = std::find(begin,end,'l');
if(pp != end) ++pp;
if(pp != end) ++pp;
*term = pp;
s.assign(begin,pp);
if(s != "null")  std::shared_ptr<json_node>();
@ @c
std::string JSON::json_node::parse_number(std::string::const_iterator begin,
		const std::string::const_iterator end,
		std::string::const_iterator* term)
{
	int state = 0;
	std::string ret;
	std::string::const_iterator begin_token = begin;
	while(begin != end && state >= 0) {
		@<Walk the state table@>@;
		++begin;
	}
	return ret;
}
@ @<Walk the state table@>=
switch(state) {
case 0: @<Handle case 0 in |json_node::parse_number|@>@;@+break;
case 1: @<Handle case 1 in |json_node::parse_number|@>@;@+break;
case 2: @<Handle case 2 in |json_node::parse_number|@>@;@+break;
case 3: @<Handle case 3 in |json_node::parse_number|@>@;@+break;
case 4: @<Handle case 4 in |json_node::parse_number|@>@;@+break;
case 5: @<Handle case 5 in |json_node::parse_number|@>@;@+break;
case 6: @<Handle case 6 in |json_node::parse_number|@>@;@+break;
case 7: @<Handle case 7 in |json_node::parse_number|@>@;@+break;
default: state = -1;
	ret.clear();
}
@ @<Handle case 0 in |json_node::parse_number|@>=
switch(*begin) {
	case '-': state = 1;@+break;
	case '0': state = 2;@+break;
	case '1': case '2': case '3': case '4': case '5':
	case '6': case '7': case '8': case '9':
		state = 3;@+break;
	default: state = -1; break;
}
@ @<Handle case 1 in |json_node::parse_number|@>=
switch(*begin) {
	case '0': state = 2;@+break;
	case '1': case '2': case '3': case '4': case '5':
	case '6': case '7': case '8': case '9':
		state = 3;@+break;
	default: state = -1; break;
}
@ @<Handle case 2 in |json_node::parse_number|@>=
switch(*begin) {
	case '.': state = 4;@+break;
	case 'e': case 'E': state = 6;@+break;
	default: ret.assign(begin_token,begin);
		state = -1;
		*term = begin;
		break;
}
@ @<Handle case 3 in |json_node::parse_number|@>=
switch(*begin) {
	case '.': state = 4;@+break;
	case '1': case '2': case '3': case '4': case '5':
	case '6': case '7': case '8': case '9': case '0':break;
	case 'e': case 'E': state = 6;@+break;
	default: ret.assign(begin_token,begin);
		state = -1;
		*term = begin;
		break;
}
@ @<Handle case 4 in |json_node::parse_number|@>=
switch(*begin) {
	case '1': case '2': case '3': case '4': case '5':
	case '6': case '7': case '8': case '9': case '0': state = 5;break;
	default:
		state = -1;
		*term = begin;
		break;
}
@ @<Handle case 5 in |json_node::parse_number|@>=
switch(*begin) {
	case 'e': case 'E': state = 6;@+break;
	default: ret.assign(begin_token,begin);
		state = -1;
		*term = begin;
		break;
}
@ @<Handle case 6 in |json_node::parse_number|@>=
switch(*begin) {
	case '-': case '+':
	case '1': case '2': case '3': case '4': case '5':
	case '6': case '7': case '8': case '9': case '0': state = 7;break;
}
@ @<Handle case 7 in |json_node::parse_number|@>=
switch(*begin) {
	case '1': case '2': case '3': case '4': case '5':
	case '6': case '7': case '8': case '9': case '0': break;
	default:
		state = -1;
		*term = begin;
		ret.assign(begin_token,begin);
		break;
}
@ @<Header inclusions@>=
#include <vector>
#include <map>
#include <string>
#include <algorithm>
#include "json.h"
#include <iostream>
@ @c
class json_escaped {
public:
	friend std::ostream& operator<<(std::ostream& os, const json_escaped& je);
	json_escaped(const std::string& st) : s(st) {}
private:
	private: std::string s;
	json_escaped(); // Not implemented
};
@ @c
std::ostream& operator<<(std::ostream& os, const json_escaped& je)
{
	for(auto si = je.s.begin(); si != je.s.end(); ++si) {
		switch(*si) {
			case '"': case '\\':
				os << "\\" << *si; break;
			case '\b': os << "\\b"; break;
			case '\f': os << "\\f"; break;
			case '\n': os << "\\n"; break;
			case '\r': os << "\\r"; break;
			case '\t': os << "\\t"; break;
			default:
				os << *si;
				break;
		}
	}
	return os;
}
@ @c
std::ostream& JSON::json_node::print(std::ostream& os,const char* prefix) const
{
	switch(type) {
		case json_string: os << '"' << json_escaped(data) << '"';@+break;
		case number: os << data;@+break;
		case object: @<Pretty-print a JSON object@>@;@+break;
		case array: @<Pretty-print a JSON array@>@;@+break;
		case json_bool: os << std::boolalpha << bdata;@+break;
		case json_null: os << "null";@+break;
		default: break;
	}
	return os;
}
@ @<Pretty-print a JSON object@>={
	os << '{';
	auto jnp = this;
	if(!obj_data.empty()) os << std::endl;
	for(auto p = obj_data.begin(); p != obj_data.end(); ) {
		@<Apply header indentation@>@;
		os << '"' << p->first << "\" : ";
		p->second->print(os,prefix);
		++p;
		if(p != obj_data.end()) os << ',';
		os << std::endl;
	}
	if(!obj_data.empty()) @<Apply trailer indentation@>@;
	os << '}';
}
@ @<Pretty-print a JSON array@>={
	auto jnp = this;
	os << '[';
	if(!obj_array.empty()) os << std::endl;
	for(auto q = obj_array.begin(); q != obj_array.end();) {
		@<Apply header indentation@>@;
		(*q)->print(os,prefix);
		++q;
		if(q != obj_array.end()) os << ',';
		os << std::endl;
	}
	if(!obj_array.empty()) @<Apply trailer indentation@>@;
	os << ']';
}
@ @<Apply header indentation@>=
if(prefix)
	os << prefix;
jnp = this;
while(jnp) {
	os << '\t';
	jnp = jnp->parent;
}
@ @<Apply trailer indentation@>={
	if(prefix)
		os << prefix;
	jnp = this->parent;
	while(jnp) {
		os << '\t';
		jnp = jnp->parent;
	}
}
@ @c
const JSON::json_node& JSON::json_node::operator[](const std::string& name) const
{
	auto p = get(name);
	return (p)?(*p):def;
}
@ @c
const JSON::json_node& JSON::json_node::operator[](unsigned int idx) const
{
	auto p = get(idx);
	return (p)?(*p):def;
}
