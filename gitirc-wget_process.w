@
@s map int
@s map make_pair
@s Process int
@s wget_process int
@s RSSreader int
@s rss_node int
@s rss_stack_node int
@s std int
@s string int
@s iterator int
@s vector int
@s vector make_pair
@s list int
@s list make_pair
@s const_iterator int
@(gitirc-wget_process.h@>=
#ifndef GITIRC_WGET_PROCESS_H
#define GITIRC_WGET_PROCESS_H
#include "gitirc-Process.h"
#include "gitirc-RSSreader.h"
#include <string>
#include <map>
#include <list>
#include <vector>
class irc_id;
class wget_process : public Process, public RSSreader {
public:
	wget_process(std::vector<const char*>& argv);
	~wget_process()@+{}
	static std::string wgeturl;
	static std::string wgetpath;
	void queue_messages();
	void fix_time();
	bool process_feed();
	static int maxpubtime;
	static int verbosity;
private:
	wget_process();
	wget_process& operator=(const wget_process& gp);
};
#endif // |GITIRC_WGET_PROCESS_H|
@ @<Variables for |wget_process|@>=
std::string wget_process::wgeturl;
std::string wget_process::wgetpath;
int wget_process::verbosity = 1;
int wget_process::maxpubtime;
@ @c
#include "gitirc-wget_process.h"
#include "gitirc-irc_id.h"
#include <sstream>
#include <time.h>
#include <iostream>
#include <cstring>
#include <algorithm>
#include <unistd.h>
@<Variables for |wget_process|@>@;
wget_process::wget_process(std::vector<const char*>& argv) :
	Process(wgetpath.c_str(),argv) {}
@ @c
bool wget_process::process_feed()
{
	bool ret = true;
	for(;;) {
		if(finished()) break;
		auto s=next();
		if(s.empty()) continue;
		for(auto p = s.begin(); p != s.end(); ++p)
			if(!insert(*p)) { ret = false; break; }
		if(!insert('\n')) { ret =  false; break; }
	}
	return ret;
}
@ @c
void wget_process::fix_time()
{
	if(process_feed())
		for(auto p = st().begin(); p != st().end(); ++p) {
			auto q = p->rn.get();
			@<Search through the first nodes of the RSS reader@>@;
		}
}
@ @<Search through the first nodes of the RSS reader@>=
for(auto r = q->children.begin(); r != q->children.end(); ++r)
	@<Search through the second level of nodes in the reader@>@;
@ @<Search through the second level of nodes in the reader@>=
for(auto s = (*r)->children.begin(); s != (*r)->children.end(); ++s)
	for(auto tt = (*s)->children.begin(); tt != (*s)->children.end(); ++tt)
		if((*tt)->name == "pubDate") {
			struct tm tmz;
			memset(&tmz,'\0',sizeof(struct tm));
			strptime((*tt)->value.c_str(),"%A, %d %B %Y %T %Z",&tmz);
			time_t pubtime = mktime(&tmz);
			if(pubtime > maxpubtime)
				maxpubtime = pubtime;
			break;
		}
@ @c
void wget_process::queue_messages()
{
	static const std::string stitle("title");
	static const std::string sdescription("description");
	static const std::string spubDate("pubDate");
	static const std::string slink("link");
	time_t maxtime = maxpubtime;
	std::map<std::string,std::string> pubMap;

	for(auto p = st().begin(); p != st().end(); ++p) {
		if(p->t == RSSreader::node_type){
			auto q = p->rn.get();
			@<Iterate over the first nodes of the RSS reader@>@;
		}
	}
	if(maxtime > maxpubtime)
		maxpubtime = maxtime;
}
@ @<Iterate over the first nodes of the RSS reader@>=
for(auto r = q->children.begin(); r != q->children.end(); ++r)
	@<Iterate over the second level of nodes in the reader@>@;
@ @<Iterate over the second level of nodes in the reader@>=
for(auto s = (*r)->children.begin(); s != (*r)->children.end(); ++s) {
	if((*s)->name == "lastBuildDate") {
		struct tm tmz;
		memset(&tmz,'\0',sizeof(struct tm));
		strptime((*s)->value.c_str(),"%A, %d %B %Y %T %Z",&tmz);
		time_t pubtime = mktime(&tmz);
		if(pubtime <= maxpubtime)
			return;
	}
	if((*s)->name == "item") {
		pubMap.clear();
		for(auto tt = (*s)->children.begin(); tt != (*s)->children.end(); ++tt)
			pubMap[(*tt)->name] = (*tt)->value;
		@<Check the node and see if we should publish it@>@;
	}
}
@ @<Check the node and see if we should publish it@>=
struct tm tmz;
memset(&tmz,'\0',sizeof(struct tm));
strptime(pubMap[spubDate].c_str(),"%A, %d %B %Y %T %Z",&tmz);
time_t pubtime = mktime(&tmz);
@ @<Check the node and see if we should publish it@>=
int verb = 1;
if( (pubMap[stitle].find("Create") == 0 || pubMap[stitle].find("Resolved") == 0))
	verb = 2;
if( pubMap[stitle].find("Milestone") != std::string::npos ||
		pubMap[stitle].find("Check-in") != std::string::npos)
	verb = 0;
if(pubtime > maxpubtime && verb > verbosity) {
	size_t off;
	@<Convert C0 escapes to html@>@;
	@<Trim out HTML tags@>@;
	std::stringstream ss;
	ss << pubMap[stitle] << " " << pubMap[sdescription]
		<< " " << pubMap[slink] << '\n';
	::write(1,ss.str().data(),ss.str().size());
}
if(pubtime > maxtime)
	maxtime = pubtime;
@ @<Convert C0 escapes to html@>=
bool found_control = true;
while(pubMap[sdescription].find("&") != std::string::npos && found_control)
	if((off = pubMap[sdescription].find("&quot;")) != std::string::npos)
		pubMap[sdescription].replace(off,6,"\"");
	else if((off = pubMap[sdescription].find("&amp;")) != std::string::npos)
		pubMap[sdescription].replace(off,5,"&");
	else if((off = pubMap[sdescription].find("&lt;")) != std::string::npos)
		pubMap[sdescription].replace(off,4,"<");
	else if((off = pubMap[sdescription].find("&gt;")) != std::string::npos)
		pubMap[sdescription].replace(off,4,">");
	else found_control = false;
@ @<Trim out HTML tags@>=
while((off = pubMap[sdescription].find("</a>")) != std::string::npos)
	pubMap[sdescription].erase(off,4);
while((off = pubMap[sdescription].find("<a href")) != std::string::npos) {
	auto hr_begin = pubMap[sdescription].begin() + off;
	auto hr_end = find(hr_begin+1,pubMap[sdescription].end(),'>');
	pubMap[sdescription].erase(hr_begin,hr_end+1);
}
while((off = pubMap[sdescription].find("<i>")) != std::string::npos)
	pubMap[sdescription].erase(off,3);
while((off = pubMap[sdescription].find("<br>")) != std::string::npos)
	pubMap[sdescription].erase(off,4);
while((off = pubMap[sdescription].find("</i>")) != std::string::npos)
	pubMap[sdescription].erase(off,4);
