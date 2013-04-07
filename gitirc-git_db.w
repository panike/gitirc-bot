@q This file defines standard C++ namespaces and classes @>
@q Please send corrections to saroj-tamasa@@worldnet.att.net @>
@s std int
@s rel_ops int
@s bitset int
@s char_traits int
@s deque int
@s list int
@s map int
@s multimap int
@s multiset int
@s pair int
@s set int
@s stack int
@s exception int
@s logic_error int
@s runtime_error int
@s domain_error int
@s invalid_argument int
@s length_error int
@s out_of_range int
@s range_error int
@s overflow_error int
@s underflow_error int
@s iterator int
@s const_iterator int
@s ref_holder int
@s irc_id int
@s gitirc_logger int
@s back_insert_iterator int
@s front_insert_iterator int
@s insert_iterator int
@s reverse_iterator int
@s istream_iterator int
@s ostream_iterator int
@s istreambuf_iterator int
@s ostreambuf_iterator int
@s iterator_traits int
@s queue int
@s vector int
@s basic_string int
@s string int
@s auto_ptr int
@s valarray int
@s ios_base int
@s basic_ios int
@s basic_streambuf int
@s basic_istream int
@s basic_ostream int
@s basic_iostream int
@s basic_stringbuf int
@s basic_istringstream int
@s basic_ostringstream int
@s basic_stringstream int
@s basic_filebuf int
@s basic_ifstream int
@s basic_ofstream int
@s basic_fstream int
@s ctype int
@s collate int
@s collate_byname int
@s streambuf int
@s istream int
@s ostream int
@s iostream int
@s stringbuf int
@s istringstream int
@s ostringstream int
@s stringstream int
@s filebuf int
@s ifstream int
@s ofstream int
@s fstream int
@s wstreambuf int
@s wistream int
@s wostream int
@s wiostram int
@s wstringbuf int
@s wistringstream int
@s wostringstream int
@s wstringstream int
@s wfilebuf int
@s wifstream int
@s wofstream int
@s wfstream int
@s streamoff int
@s streamsize int
@s fpos int
@s streampos int
@s wstreampos int
@
@s git_process int
@s Process int
@s std int
@s string int @(gitirc-git_db.h@>=
#ifndef GITIRC_GIT_DB_H
#define GITIRC_GIT_DB_H
#include <string>
#include <map>
#include <list>
#include <vector>
#include <set>
#include <algorithm>
#include "gitirc-irc_id.h"
#include <climits>
class git_db {
public:
	@<Public |git_db| interface@>@;
	@<Helper structure definitions@>@;
private:
	git_db(); // Not implemented
	@<Private |git_db| data@>@;
	@<Private helper |git_db| functions@>@;
};
#endif // |GITIRC_GIT_DB_H|
@ @c
#include "gitirc-git_db.h"
#include "gitirc-git_process.h"
#include "gitirc-get_refname.h"
#include "gitirc-get_sha1.h"
#include "gitirc-logger.h"
#include "gitirc-is_interesting_ref.h"
#include <iostream>
#include <sstream>
#include <cstring>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
extern gitirc_logger userlog;
@<Internal helper structures@>@;
@<Helper function definitions@>@;
@ A map to hold the references.  The key is the name of the reference, and the
value is the SHA-1 name of the content.
@<Public |git_db| interface@>=
private:
std::map<std::string,std::string> db;
public:
const std::map<std::string,std::string>& get_refs() const {
	return db;
}
@ An exception class if we need to throw.
@<Public |git_db| interface@>=
class exc {};
@ @<Public |git_db| interface@>=
git_db(const std::map<std::string,std::string>& conf, bool dorl = true);
@ @<Private |git_db| data@>=
time_t corr_mtime;
bool should_renew_crefs;
std::string repo;
std::string email_script;
std::string shorten_url;
std::string change_url;
std::string build_url;
@ @c git_db::git_db(const std::map<std::string,std::string>& conf, bool dorl) :
	corr_mtime(0)
{
	auto ci = conf.find("gitrepo");
	if(ci == conf.end()) throw exc();
	else repo = ci->second;
	if((ci = conf.find("shorten")) != conf.end())
		shorten_url = ci->second;
	if((ci = conf.find("corruption_email")) != conf.end())
		email_script = ci->second;
	if((ci = conf.find("change")) != conf.end())
		change_url = ci->second;
	if((ci = conf.find("build_prefix")) != conf.end())
		build_url = ci->second;
	if((ci = conf.find("gitpath")) != conf.end())
		git_process::gitpath = ci->second;
	if((ci = conf.find("gitrepo")) != conf.end())
		git_process::gitrepo = ci->second;
	if((ci = conf.find("log")) != conf.end()) init(ci->second,dorl);
	should_renew_crefs = true;
	renew_crefs();
}
@ @<Private helper |git_db| functions@>=
void init(const std::string& logname,bool dorl);
@ @c void git_db::init(const std::string& logname, bool dorl)
{
	std::ifstream log(logname.c_str());
	if(!log) throw exc();
	std::string s;
	while(std::getline(log,s)) handle_lsr_line(s,db);
	if(dorl) {
		@<Initialize the table of ``seen'' commits@>@;
	}
}
@ @<Helper function definitions@>=
namespace {
void handle_lsr_line(const std::string& s,std::map<std::string,std::string>& lsr)
{
	auto t = get_refname(s);
	if(t == "HEAD") return;
	auto is_dereferenced_tag = false;
	auto pp = t.find("^{}");
	if(pp != std::string::npos) {
		is_dereferenced_tag = true;
		t = t.substr(0,pp);	
	}
	if(t.find("refs/remotes/") == 0) return;
	auto p=lsr.insert(std::make_pair(t,get_sha1(s)));
	if(!p.second) {
		if(is_dereferenced_tag) p.first->second = get_sha1(s);
		else userlog << "Attempt to insert \"" << t << "\" twice?\n";
	}
}}
@ First part is to get the list of heads that we finished with last time. Then
we deduplicate it.
@<Initialize the table of ``seen'' commits@>=
std::vector<std::string> shas;
for(auto p = db.begin(); p != db.end(); ++p) shas.push_back(p->second);
std::sort(shas.begin(),shas.end());
shas.erase(std::unique(shas.begin(),shas.end()),shas.end());
@ 
@<Initialize the table of ``seen'' commits@>=
std::vector<const char*> argv;
argv.push_back("git");
std::string repo("--git-dir=");
repo.append(git_process::gitrepo);
argv.push_back(repo.c_str());
argv.push_back("rev-list");
@ We do not want to run \.{rev-list} with \.{--all} argument, since we might be
starting up and there might have been commits while we were off. Thus we have
to use the list of SHA-1's that we recorded earlier.
@<Initialize the table of ``seen'' commits@>=
for(auto p = shas.begin(); p != shas.end(); ++p) argv.push_back(p->c_str());
git_process rl(argv);
for(;;) {
	if(rl.finished()) break;
	s = rl.next();
	if(!s.empty()) already_seen.insert(s);
}
if(rl.check_status()) {
	userlog << "Failed to list commits" << std::endl;
	_exit(1);
}
userlog << "We have a set of " << already_seen.size() << " commits" << std::endl;
@ @<Public |git_db| interface@>=
std::list<irc_id> update();
@ @c
std::list<irc_id> git_db::update()
{
	std::list<irc_id> messages;
	std::map<std::string,std::string> new_refs;
	@<Query the remote for the new references@>@;
	@<Compile a list of new and deleted references@>@;
	@<For each new commit, write a message@>@;
	renew_crefs();
	return messages;
}
@ @<Query the remote for the new references@>=
@<Run \.{git ls-remote} to get the list of references@>@;
for(;;) {
	if(lsr.finished()) break;
	auto s = lsr.next();
	if(!s.empty()) handle_lsr_line(s,new_refs);
}
@ @<Run \.{git ls-remote} to get the list of references@>=
fetch();
std::vector<const char*> argv;
argv.push_back("git");
argv.push_back("ls-remote");
argv.push_back(repo.c_str());
git_process lsr(argv);
@ @<Compile a list of new and deleted references@>=
auto op = db.begin();
auto np = new_refs.begin();
while(op != db.end() && np != new_refs.end()) {
	if(op->first < np->first) post_deletion(messages,op);
	else if(op->first > np->first) post_new_reference(messages,np);
	else {
		++op;
		++np;
	}
}
while(op != db.end()) post_deletion(messages,op);
while(np != new_refs.end()) post_new_reference(messages,np);
@ @<Private helper |git_db| functions@>=
void post_deletion(std::list<irc_id>& m,
	std::map<std::string,std::string>::iterator& p);
@ @<Private helper |git_db| functions@>=
void post_new_reference(std::list<irc_id>&,
	std::map<std::string,std::string>::iterator&);
@ @c void git_db::post_deletion(std::list<irc_id>& m,
	std::map<std::string,std::string>::iterator& p)
{
	std::stringstream message;
	std::string tagname;
	if(p->first.find("refs/heads/") == 0) {
		auto s = get_basename(p->first);	
		if(is_interesting_ref(s))
			should_renew_crefs = true;
		message << "Branch " << s << " deleted";
	}@+else if(p->first.find("refs/tags/") == 0) {
		tagname = get_basename(p->first);
		message << "Tag " << tagname << " deleted";
	}@+else message << "Ref " << p->first << " deleted.";
	if(tagname.find("^{}") == std::string::npos && !message.str().empty())
		m.push_back(message.str());
	auto te = p++;
	db.erase(te);
}
@ @c void git_db::post_new_reference(std::list<irc_id>& m,
	std::map<std::string,std::string>::iterator& p)
{
	std::stringstream message;
	std::string tagname;
	message << "New ";
	if(p->first.find("refs/heads/") == 0) {
		auto s = get_basename(p->first);
		if(is_interesting_ref(s))
			should_renew_crefs = true;
		message << "branch " << s << " created";
	}@+else if(p->first.find("refs/tags/") == 0) {
		tagname = get_basename(p->first);
		message << "tag " << tagname << " created";
	}@+else message << "ref " << p->first << " created.";
	if(tagname.find("^{}") == std::string::npos && !message.str().empty())
		m.push_back(message.str());
	++p;
}
@ @<For each new commit, write a message@>=
op = db.begin();
np = new_refs.begin();
std::vector<ref_holder> rh;
while(op != db.end() && np != new_refs.end()) {
	if(op->first < np->first) @<A deleted reference! This should not happen@>@;
	else if(op->first > np->first) @<A new reference. Record it in |rh|@>@;
	else if(op->second != np->second) @<Also record this one in |rh|@>@;
	else {
		++op;
		++np;
	}
}
while(op != db.end()) @<A deleted reference! This should not happen@>@;
while(np != new_refs.end()) @<A new reference. Record it in |rh|@>@;
@ @<For each new commit, write a message@>=
std::sort(rh.begin(),rh.end(),SortCommits(*this));
auto lit = messages.begin();
for(auto rhi = rh.begin(); rhi != rh.end(); ++rhi)
	@<Print out the commits for |rhi|@>@;
@ @<Print out the commits for |rhi|@>={
	auto p = db.find(rhi->refname);
	if(rhi->refname.find("refs/heads/") == 0) {
		rhi->count = get_count(rhi->name);
		if(rhi->count > 0) {
			auto tmessages = list_commits(rhi->refname,rhi->name,true);
			if(!tmessages.empty()) messages.insert(lit,tmessages.begin(),tmessages.end());
			else {
				std::stringstream to_gitirc;
				to_gitirc << get_basename(rhi->refname) << " fast-forwarded to "
					<< short_sha1(rhi->name);
				messages.insert(lit,irc_id(to_gitirc.str()));
			}
		}@+else if(p != db.end() && rhi->count == 0)
			@<Decide whether the commit is a reset or a fast-forward@>@;
		else if(rhi->count < 0) userlog << "Error writing out commits for "
			<< rhi->refname << std::endl;
	}
	@<Update |db| from |rhi|@>@;
}
@ @<Decide whether the commit is a reset or a fast-forward@>={
	std::vector<const char*> rlargv;
	rlargv.push_back("git");
	std::string rep("--git-dir=");
	rep.append(repo);
	rlargv.push_back(rep.c_str());
	rlargv.push_back("rev-list");
	rlargv.push_back("--count");
	rlargv.push_back("--ancestry-path");
	rlargv.push_back(rhi->name.c_str());
	rlargv.push_back("--not");
	rlargv.push_back(p->second.c_str());
	git_process rl(rlargv);
	int num=std::atoi(rl.next().c_str());
	std::stringstream to_gitirc;
	to_gitirc << get_basename(rhi->refname) << ((num<=0)?" reset":" fast-forwarded") <<
		" to " << short_sha1(rhi->name);
	messages.insert(lit,irc_id(to_gitirc.str()));
}
@ @<Update |db| from |rhi|@>=
if(p != db.end()) {
	userlog << "Updating " << rhi->refname << " to " << rhi->name << std::endl;
	@<Check the update to make sure it is legal@>@;
	p->second = rhi->name;
}@+else {
	userlog << "Inserting " << rhi->refname << " at " << rhi->name << std::endl;
	auto pp = db.insert(std::make_pair(rhi->refname,rhi->name));
	if(!pp.second)
		userlog << "Could not insert \"" << rhi->refname << "\" into db" << std::endl;
}
@ @<Public |git_db| interface@>=
static std::string get_basename(const std::string& s, int trim = 2);
@ @c
std::string git_db::get_basename(const std::string& s,int trim)
{
	auto pp = s.begin();
	for(auto ii=0;ii<trim;++ii) {
		auto qq = std::find(pp,s.end(),'/');
		if(qq != s.end()) pp = qq + 1;
		else break;
	}
	return std::string(pp,s.end());
}
@ @<Private |git_db| data@>=
std::vector<std::string> crefs;
@ @<Check the update to make sure it is legal@>=
auto bname = get_basename(rhi->refname);
for(auto cii = crefs.begin(); cii != crefs.end(); ++cii)
	if(cii != crefs.begin() && *cii == bname) {
		userlog << "Examining \"" << *cii << "\" for corruption." << std::endl;
		std::vector<std::string> stable_refs;
		get_commit_set(&stable_refs,rhi->name,p->second,(std::vector<std::string>()));
		for(auto ci2 = crefs.begin(); ci2 != cii; ++ci2)
			@<Check commits that are in |ci2|@>@;
		break;
	}
@ @<Check commits that are in |ci2|@>={
	userlog << "Checking for commits from \"" << *ci2 << "\" in \"" << *cii << "\""
		<< std::endl;
	std::vector<std::string> dev_refs;
	std::string start_dev = "refs/heads/";
	start_dev.append(*ci2);
	auto mi = db.find(start_dev);
	if(mi == db.end()) {
		userlog << "Did not find \"" << start_dev << "\" in db" << std::endl;
		break;
	}
	std::vector<std::string> extras;
	get_commit_set(&dev_refs,mi->second,p->second,extras);
	std::sort(dev_refs.begin(),dev_refs.end());
	auto si = stable_refs.begin();
	@<Compare the lists of commits@>@;
	if(si != stable_refs.end()) 
		@<Do a secondary test to check for unmerged stable release@>@;
}
@ @<Do a secondary test to check for unmerged stable release@>={
	userlog << "Doing secondary test with " << *cii << " and " << *ci2 << std::endl;
	std::string corrupted_commit;
	dev_refs.clear();
	extras.assign(cii+1,crefs.end());
	if(!extras.empty()) {
		std::vector<std::string> stable_refs_e;
		get_commit_set(&dev_refs,mi->second,p->second,extras);
		std::sort(dev_refs.begin(),dev_refs.end());
		get_commit_set(&stable_refs_e,rhi->name,p->second,extras);
		@<Compare lists for stable merge@>@;
	}@+else corrupted_commit = *si;
	@<Send an email if corruption is confirmed@>@;
	@<Send a \\{mea culpa} if no corruption occurred@>@;
}
@ @<Private helper |git_db| functions@>=
void get_commit_set(std::vector<std::string>*,const std::string& top,
	const std::string& bottom, const std::vector<std::string>& extra) const;
@ @c void git_db::get_commit_set(std::vector<std::string>* lst,const std::string& top,
	const std::string& bottom,const std::vector<std::string>& extra) const
{
	std::vector<const char*> argv;
	@<Prepare the \.{rev-list} command line@>@;
	git_process rl(argv);
	for(;;) {
		if(rl.finished()) break;
		auto s=rl.next();
		if(!s.empty()) lst->push_back(s);
	}
}
@ @<Prepare the \.{rev-list} command line@>=
argv.push_back("git");
std::string repos("--git-dir=");
repos.append(repo);
argv.push_back(repos.c_str());
argv.push_back("rev-list");
argv.push_back(top.c_str());
argv.push_back("--not");
argv.push_back(bottom.c_str());
for(auto exi = extra.begin(); exi != extra.end(); ++exi)
	argv.push_back(exi->c_str());
@ Writing it this way will find the latest example of corruption. Previous
version would find the earliest (lexicographically) which is pretty useless for
figuring out what went wrong.
@<Compare the lists of commits@>=
for(; si != stable_refs.end(); ++si)
	if(std::binary_search(dev_refs.begin(),dev_refs.end(),*si)) {
		std::stringstream report_stable_corruption;
		report_stable_corruption << "Possible corruption of " << *cii << " at "
			<< short_sha1(*si) << ", which is also in " << *ci2 << ". " << *cii
			<< " now at " << short_sha1(rhi->name) << ".  " << *ci2 << " is at "
			<< short_sha1(mi->second) << ".  Base at " << short_sha1(p->second);
		messages.push_back(irc_id(report_stable_corruption.str()));
		break; // No reason to print more than one
	}
@ @<Compare lists for stable merge@>=
for(si = stable_refs_e.begin(); si != stable_refs_e.end(); ++si)
	if(std::binary_search(dev_refs.begin(),dev_refs.end(),*si)) {
		userlog << "Corruption confirmed" << std::endl;
		corrupted_commit = *si;
		break;
	}
@ @<Send an email if corruption is confirmed@>= 
if(!corrupted_commit.empty() && !email_script.empty()) {
	std::vector<const char*> pargv;
	pargv.push_back(email_script.c_str());
	pargv.push_back(ci2->c_str());
	pargv.push_back(cii->c_str());
	std::string tmp0, tmp1, tmp2, tmp3;
	tmp0 = short_sha1(corrupted_commit);@+pargv.push_back(tmp0.c_str());
	tmp1 = short_sha1(mi->second);@+pargv.push_back(tmp1.c_str());
	tmp2 = short_sha1(rhi->name);@+pargv.push_back(tmp2.c_str());
	tmp3 = short_sha1(p->second);@+pargv.push_back(tmp3.c_str());
	Process git_warn(pargv[0],pargv);
}
@ @<Send a \\{mea culpa} if no corruption occurred@>=
if(corrupted_commit.empty()) {
	std::string report_stable_corruption("Seems to be a false positive (failure"
		" to merge stable through point release?)");
	messages.push_back(irc_id(report_stable_corruption));
}
@ @<A deleted reference! This should not happen@>={
	userlog << "Deleted reference \"" << op->first << "\" should have been "
		"taken care of" << std::endl;
	auto te = op++;
	db.erase(te);
}
@ @<A new reference. Record it in |rh|@>={
	rh.push_back(ref_holder(np->first,np->second));
	++np;
}
@ @<Also record this one in |rh|@>={
	@<Complain if |np| points to a tag@>@;
	rh.push_back(ref_holder(np->first,np->second));
	++np;
	++op;
}
@ @<Complain if |np| points to a tag@>=
if(np->first.find("refs/tags") == 0) {
	userlog << "Someone moved tag \"" << np->first << "\"" << std::endl;
	std::stringstream m;
	m << "Tag " << np->first << " moved. Tags are not expected to move" << std::endl;
	messages.push_back(irc_id(m.str()));
}
@ @<Public |git_db| interface@>=
int get_count(const std::string& sha1) const;
@ @c
int git_db::get_count(const std::string& sha1) const
{
	std::vector<const char*> argv;
	argv.push_back("git");
	std::string re = "--git-dir=";
	re.append(repo);
	argv.push_back(re.c_str());
	argv.push_back("rev-list");
	argv.push_back("--count");
	argv.push_back(sha1.c_str());
	argv.push_back("--not");
	for(auto p = db.begin(); p != db.end(); ++p)
		if(p->first.find("refs/heads/") == 0)
			argv.push_back(p->second.c_str());
	git_process rlc(argv);
	auto t = rlc.next();
	if(rlc.check_status() != 0)
		return -1;
	return std::atoi(t.c_str());
}
@ @<Public |git_db| interface@>=
std::list<irc_id> list_commits(const std::string& refname, const std::string& sha1,
	bool build);
@ @<Private |git_db| data@>=
std::set<std::string> already_seen;
@ @c std::list<irc_id> git_db::list_commits(const std::string& refname,
		const std::string& sha1, bool build)
{
	std::list<irc_id> m;
	@<Run \.{git log} on ref |refname|@>@;
	@<Find the basename of the ref@>@;
	auto loop_counter = 0;
	for(;;) {
		if(log.finished()) break;
		auto s = log.next();
		if(s.empty()) continue;
		auto sn = short_name(s);
		auto longname = (loop_counter==0)?sha1:rev_parse(sn);
		++loop_counter;
		auto is_merge = remove_parents(&s);
		if(has_seen(longname)) continue;
		else already_seen.insert(longname);
		if(is_tag) continue;
		std::stringstream logstring;
		@<Output the log message@>@;
		auto change = get_change_url(sn);
		if(!change.empty()) logstring << " " << change;
		if(build && is_interesting_ref(basename))
			@<Append the NMI build string@>@;
		if(!logstring.str().empty()) m.push_front(logstring.str());
	}
	return m;
}
@ Decides whether this parent is a merge commit.  As a side effect, it deletes
the parent hashes from the log string.
@<Helper function definitions@>=
namespace {
std::vector<std::string> remove_parents(std::string* s)
{
	std::vector<std::string> ret;
	if(!s) return ret;
	auto p = std::find(s->begin(),s->end(),'[');
	auto q = std::find(p,s->end(),']');
	if(p == s->end() || q == s->end()) return ret;
	for(auto r = p+1; r != q;) {
		auto st = std::find(r,q,' ');
		std::string str(r,st);
		if(!str.empty()) ret.push_back(str);
		if(st != q) ++st;
		r = st;
	}
	if(q != s->end()) ++q; // Skip over ']'
	if(q != s->end()) ++q; // Skip over space
	s->erase(p,q);
	return ret;
}
}
@ @<Find the basename of the ref@>=
bool is_branch = (refname.find("refs/heads/") == 0);
bool is_tag = (refname.find("refs/tags/") == 0);
std::string basename(refname);
if(is_branch || is_tag) basename = get_basename(basename);
@ @<Run \.{git log} on ref |refname|@>=
std::vector<const char*> argv;
argv.push_back("git");
argv.push_back("--no-pager");
std::string re = "--git-dir=";
re.append(repo);
argv.push_back(re.c_str());
argv.push_back("log");
argv.push_back("--pretty=format:%h [%p] %s (%an)");
argv.push_back(sha1.c_str());
argv.push_back("--not");
for(auto p = db.begin(); p != db.end(); ++p)
	if(p->first.find("refs/heads/") == 0)
		argv.push_back(p->second.c_str());
git_process log(argv);
@ If the commit is not a merge, we have a simple git.io link to resolve.
@<Output the log message@>=
logstring << "Update to " << (is_branch?"branch":(is_tag?"tag":"ref")) << " "
	<< basename << ": " << s;
#if 0
userlog << "Log string is \"" << logstring.str() << "\"" << std::endl;
#endif
auto short_url = get_short_gh_url(sn,is_merge);
if(!short_url.empty()) logstring << " " << short_url;
@ @<Private helper |git_db| functions@>=
std::string get_short_gh_url(const std::string& sn,
	const std::vector<std::string>& parents) const;
@ @c
std::string git_db::get_short_gh_url(const std::string& sn,
		const std::vector<std::string>& parents) const
{
	std::string ret;
	if(!shorten_url.empty()) {
		if(parents.size() < 2)
			ret = get_short_gh_url_simple(sn);
		else {
			std::vector<const char*> argv;
			argv.push_back(shorten_url.c_str());
			auto mincommit = get_minimal(sn,parents);
			argv.push_back(mincommit.c_str());
			argv.push_back(sn.c_str());
			Process shorten(argv[0],argv);
			ret = shorten.next();
		}
	}
	return ret;
}
@ @<Private helper |git_db| functions@>=
std::string get_short_gh_url_simple(const std::string& shortsha1) const
{
       return simple_callout(shorten_url,shortsha1);
}
@ @<Helper function definitions@>=
namespace {
std::string get_minimal(const std::string& sn, const std::vector<std::string>& parents)
{
	auto num = INT_MAX;
	std::string ret;
	for(auto p = parents.begin(); p != parents.end(); ++p) {
		std::vector<const char*> argv;
		argv.push_back("git");
		argv.push_back("--no-pager");
		std::string repo("--git-dir=");
		repo.append(git_process::gitrepo);
		argv.push_back(repo.c_str());
		argv.push_back("rev-list");
		argv.push_back("--count");
		argv.push_back(sn.c_str());
		argv.push_back("--not");
		argv.push_back(p->c_str());
		git_process count(argv);
		auto s = count.next();
		auto newnum = std::atoi(s.c_str());
		if(newnum < num) {
			num = newnum;
			ret = *p;	
		}
	}
	return ret;
}
}
@ This is for simple scripts.  Calling the script should be of the form
``\.{script} \.{arg}'', and the script should return one short line of output.
@<Private helper |git_db| functions@>=
std::string simple_callout(const std::string& script, const std::string& arg) const;
@ @c std::string git_db::simple_callout(const std::string& script,const std::string& arg) const
{
	if(script.empty()) return std::string();
	std::vector<const char*> pargv;
	pargv.push_back(script.c_str());
	pargv.push_back(arg.c_str());
	Process callout(pargv[0],pargv);
	return callout.next();
}
@ @<Append the NMI build string@>={
	build = false;
	auto builds = get_build_url(sn,false);
	if(!builds.empty()) logstring << " " << builds;
}
@ @<Public |git_db| interface@>=
std::string get_build_url(const std::string& refname, bool run_rev_parse = false) const;
@ @c std::string git_db::get_build_url(const std::string& refname, bool
	run_rev_parse) const
{
@^Hack for condor@>
	std::string longname;
	if(run_rev_parse) longname = short_sha1(rev_parse(refname));
	else longname = refname;
	if(longname.empty()) return std::string();
	if(build_url.empty()) return std::string();
	std::string ret(build_url);
	ret.append(longname);
	return ret;
}
@ @<Public |git_db| interface@>=
std::string rev_parse(const std::string& sha1) const;
@ @c std::string git_db::rev_parse(const std::string& sha1) const
{
	std::vector<const char*> argv;
	argv.push_back("git");
	std::string re("--git-dir=");
	re.append(repo);
	argv.push_back(re.c_str());
	argv.push_back("rev-parse");
	argv.push_back(sha1.c_str());
	git_process rp(argv);
	if(rp.check_status() != 0) return std::string();
	else return rp.next();
}
@ @<Public |git_db| interface@>=
std::string short_sha1(const std::string& sha1) const;
@ @c std::string git_db::short_sha1(const std::string& sha1) const
{
	std::vector<const char*> argv;
	argv.push_back("git");
	std::string re = "--git-dir=";
	re.append(repo);
	argv.push_back(re.c_str());
	argv.push_back("rev-parse");
	argv.push_back("--short");
	argv.push_back(sha1.c_str());
	git_process rp(argv);
	if(rp.check_status() != 0) return std::string();
	else return rp.next();
}
@ @<Public |git_db| interface@>=
std::string get_type(const std::string& name) const;
@ @c std::string git_db::get_type(const std::string& name) const
{
	std::vector<const char*> argv;
	std::string rep("--git-dir=");
	argv.push_back("git");
	rep.append(repo);
	argv.push_back(rep.c_str());
	argv.push_back("cat-file");
	argv.push_back("-t");
	argv.push_back(name.c_str());
	git_process cf(argv);
	if(cf.check_status() == 0) return cf.next();
	else return std::string();
}
@ @<Public |git_db| interface@>=
std::string contains(const std::string& name, const char* bt);
@ @c
std::string git_db::contains(const std::string& name, const char* bt)
{
	if(!bt) throw exc();
	std::vector<const char*> argv;
	argv.push_back("git");
	std::string rep("--git-dir=");
	rep.append(repo);
	argv.push_back(rep.c_str());
	argv.push_back(bt);
	argv.push_back("--contains");
	argv.push_back(name.c_str());
	git_process cf(argv);
	std::stringstream bc;
	for(;;) {
		if(cf.finished()) break;
		auto s = cf.next();
		if(s.empty()) continue;
@^Hack for condor repo@>
		if(s.find("BUILD") != std::string::npos) continue;
		if(!bc.str().empty()) bc << " ";
		s.erase(std::remove(s.begin(),s.end(),' '),s.end());
		s.erase(std::remove(s.begin(),s.end(),'*'),s.end());
		bc << s;
	}
	return bc.str();
}
@ @<Helper structure definitions@>=
struct ref_holder {
	std::string refname;
	std::string name;
	mutable int count;
	ref_holder() : count(-2) {}
	ref_holder(const std::string& r, const std::string& s) : refname(r), name(s), count(-2) {}
};
@ @<Internal helper structures@>=
@<Define the |SortRefs| structure@>@;
struct SortCommits {
	SortCommits(git_db& p) : gdb(p) {}
	bool operator()(const git_db::ref_holder& lhs,const git_db::ref_holder& rhs) {
		std::string lbname = git_db::get_basename(lhs.refname);
		std::string rbname = git_db::get_basename(rhs.refname);
		if(!is_interesting_ref(lbname)) {
			if(is_interesting_ref(rbname))
				return true;
			else {
				if(lhs.count == -2) lhs.count = gdb.get_count(lhs.name);
				if(rhs.count == -2) rhs.count = gdb.get_count(rhs.name);
				return lhs.count < rhs.count;
			}
		}@+else {
			if(is_interesting_ref(rbname)) {
				SortRefs sr; // To make sure table is initialized
				return sr(rbname,lbname); // We want to reverse the SortRefs ordering
			}@+else return false;
		}
	}
private:
	git_db& gdb;
	SortCommits(); // Not implemented
};
@ @<Public |git_db| interface@>=
bool has_seen(const std::string& sha1) {
	return (already_seen.find(sha1) != already_seen.end());
}
@ @<Public |git_db| interface@>=
bool check_is_commit(const std::string& refname) const;
@ @c
bool git_db::check_is_commit(const std::string& refname) const
{
	auto ret = false;
	if(refname.empty())
		return ret;
	auto reftype = get_type(refname);
	if(reftype == "commit") ret = true;
	else if(reftype == "tag") {
		auto crefname = refname;
		crefname.append("^{}");
		reftype = get_type(crefname);
		if(reftype == "commit") ret = true;
	}
	return ret;
}
@ @<Public |git_db| interface@>=
void fetch();
@ @c
void git_db::fetch()
{
	std::vector<const char*> argv;
	argv.push_back("git");
	std::string repos="--git-dir=";
	repos.append(repo);
	argv.push_back(repos.c_str());
	argv.push_back("fetch");
	argv.push_back("--quiet");
	argv.push_back("--prune");
	argv.push_back("--all");
	for(int ii=0;ii<5;++ii) {
		git_process fetchit(argv);
		if(fetchit.check_status() == 0) break;
		else {
			struct timeval tv;
			tv.tv_sec = 10;
			tv.tv_usec = 0;
			::select(0,0,0,0,&tv);
		}
	}
}
@ @<Public |git_db| interface@>=
template<bool force> std::string get_single_ref(const std::string& ref);
@ @c
template <bool force>
std::string git_db::get_single_ref(const std::string& ref)
{
	std::vector<const char*> argv;
	@<Prepare arguments for \.{git log -1}@>@;
	git_process log(argv);
	std::string ret = log.next();
	if(!ret.empty()) @<Seems to be a valid branch. Dump the info@>@;
	return ret;
}
@ If |force| is true, we want to produce output, regardless whether this is
deep in the history.  If |force| is false, we only want to see it if it is new.
@<Prepare arguments for \.{git log -1}@>=
argv.push_back("git");
argv.push_back("--no-pager");
std::string repos="--git-dir=";
repos.append(repo);
argv.push_back(repos.c_str());
argv.push_back("log");
argv.push_back("--pretty=format:%h [%p] %s (%an)");
argv.push_back("-1");
argv.push_back(ref.c_str());
if(!force) {
	argv.push_back("--not");
	for(auto p = db.begin(); p != db.end(); ++p)
		if(p->first.find("refs/heads") == 0) argv.push_back(p->second.c_str());
}
@ @<Seems to be a valid branch. Dump the info@>={
	auto sn = short_name(ret);
	auto is_merge = remove_parents(&ret);
@^Hack for github@>
	auto surl = get_short_gh_url(sn,is_merge);
	if(!surl.empty()) {
		ret.append(1,' ');
		ret.append(surl);
	}
@^Hack for condor@>
	auto cn = get_change_url(sn);
	if(!cn.empty()) {
		ret.append(1,' ');
		ret.append(cn);
	}
}
@ We force instantiation of this function.  Evidently, we do not use the
|false| version of the function.  If we do need it, we will instantiate it here
so as to not get a link error.
@s get_single_ref make_pair
@c template std::string git_db::get_single_ref<true>(const std::string& ref);
@ @<Private helper |git_db| functions@>=
std::string get_change_url(const std::string& sn) const
{
	return simple_callout(change_url,sn);
}
@ @<Public |git_db| interface@>=
std::string short_name(const std::string& lin) const {
	return std::string(lin.begin(),std::find(lin.begin(),lin.end(),' '));
}
@ @<Private helper |git_db| functions@>=
void renew_crefs();
@ @<Define the |SortRefs| structure@>=
struct SortRefs {
	SortRefs();
	static int buf[256];
	static bool inited;
	bool operator()(const std::string& a,const std::string& b);
	static bool compare(char a,char b) { return buf[int(a) & 0xff] < buf[int(b) & 0xff]; }
};
@ @<Internal helper structures@>=
int SortRefs::buf[256];
bool SortRefs::inited = false;
@ @c
SortRefs::SortRefs()
{
	if(!inited) {
		inited = true;
		for(int i=0;i<256;++i) buf[i] = i;
		std::swap_ranges(&buf[int('A')],&buf[int('Z')+1],&buf[int('a')]);	
		std::reverse(&buf[int('0')],&buf[int('9')+1]);
	}
}
@ @c
bool SortRefs::operator()(const std::string& a,const std::string& b)
{
	auto ait = a.begin();
	auto bit = b.begin();
	while(ait != a.end() && bit != b.end() && *ait == *bit) {
		++ait;
		++bit;
	}
	if(ait != a.end() && bit != b.end()) 
		return compare(*ait,*bit);
	else return (ait == a.end());
}
@ @c void git_db::renew_crefs()
{
	if(should_renew_crefs) {
		crefs.clear();
		for(auto mit = db.begin(); mit != db.end(); ++mit) {
			auto s = get_basename(mit->first);
			if(is_interesting_ref(s))
				crefs.push_back(s);
		}
		std::sort(crefs.begin(),crefs.end(),SortRefs());
		for(auto p = crefs.begin(); p != crefs.end(); ++p)
			userlog << "cref(" << std::distance(crefs.begin(),p) << ") = " << *p << std::endl;
		should_renew_crefs = false;
	}
}
@
@s unary_function int
@s unary_function make_pair
@c namespace {
class RefFinder {
public:
	operator bool() { return it != source.end(); }
	std::string get();
	RefFinder(const std::string& s);
private:
	struct spaceFinder : std::unary_function<char,bool> {
		bool operator()(char ch) const { return isspace(ch); }
	};
	std::string source;
	std::string::iterator it;
	RefFinder();
};
}
@ @c
namespace {
RefFinder::RefFinder(const std::string& s) : source(s)
{
	it = std::find_if(source.begin(),source.end(),std::not1(spaceFinder()));
}
}
@ @c
namespace {
std::string RefFinder::get()
{
	std::string result;
	if(it == source.end()) return result;
	auto p = std::find_if(it,source.end(),spaceFinder());
	result.assign(it,p);
	it = std::find_if(p,source.end(),std::not1(spaceFinder()));
	return result;
}
}
@ @<Public |git_db| interface@>=
git_db& operator=(const git_db& rhs);
@ @c
git_db& git_db::operator=(const git_db& rhs)
{
	if(this == &rhs) return *this;
	email_script = rhs.email_script;
	shorten_url = rhs.shorten_url;
	change_url = rhs.change_url;
	build_url = rhs.build_url;
	return *this;
}
@ @<Public |git_db| interface@>=
std::string get_parents(const std::string& ref) const;
@ @c
std::string git_db::get_parents(const std::string& ref) const
{
	std::string refname(ref);
	refname.append("^@@");
	std::vector<const char*> argv;
	argv.push_back("git");
	std::string gd("--git-dir=");
	gd.append(repo);
	argv.push_back(gd.c_str());
	argv.push_back("rev-parse");
	argv.push_back(refname.c_str());
	git_process gp(argv);
	std::stringstream ss;
	for(;;) {
		if(gp.finished()) break;
		auto s = gp.next();
		if(s.empty()) continue;
		if(!ss.str().empty()) ss << " ";
		ss << short_sha1(s);
	}
	return ss.str();
}
@ @<Public |git_db| interface@>=
std::string get_children(const std::string& ref) const;
@ @c
std::string git_db::get_children(const std::string& ref) const
{
	std::vector<const char*> argv;
	argv.push_back("git");
	std::string gd("--git-dir=");
	gd.append(repo);
	argv.push_back(gd.c_str());
	argv.push_back("rev-parse");
	argv.push_back(ref.c_str());
	git_process gp(argv);
	std::string sha1;
	for(;;) {
		if(gp.finished()) break;
		auto s=gp.next();
		if(s.empty()) continue;
		sha1=s;
	}
	argv.clear();
	argv.push_back("git");
	argv.push_back(gd.c_str());
	argv.push_back("rev-list");
	argv.push_back("--all");
	argv.push_back("--parents");
	argv.push_back("--not");
	argv.push_back(sha1.c_str());
	git_process rl(argv);
	std::string ret;
	for(;;) {
		if(rl.finished()) break;
		auto s=rl.next();
		if(s.empty()) continue;
		auto off = s.find(sha1);
		if(off != std::string::npos && off > 0) {
			ret.append(" ");
			ret.append(short_sha1(s.substr(0,40)));
		}
	}
	return ret;
}
