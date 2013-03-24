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
@ We process the RSS feed
@c
@<Header inclusions for \.{rrs-reader}@>@;
@<Global variable declarations for \.{rss-reader}@>@;
@ @c
int main(int argc,char* argv[], char* envp[])
{
	@<Read the command line@>@;
	@<Read the configuration file for \.{rss-reader}@>@;
	@<Check the configuration of \.{rss-reader}@>@;
	@<Read the RSS feed@>@;
	@<Write the time value@>@;
	userlog.close();
	return !pf;
}
@ @<Global variable declarations for \.{rss-reader}@>=
const char* configfilename=0;
@ @<Read the command line@>=
for(int i=1;i<argc;++i)
	if(std::strcmp("-c",argv[i]) == 0)
		configfilename = argv[++i];
if(!configfilename) ::_exit(1);
@ @<Read the command line@>=
userlog.open("rss-log",std::ios_base::out|std::ios_base::ate|std::ios_base::app);
userlog << "Running RSS reader" << std::endl;
@ @<Read the configuration file for \.{rss-reader}@>=
std::fstream config;
config.open(configfilename,std::ios_base::in);
if(!config) ::_exit(1);
@ @<Read the configuration file for \.{rss-reader}@>=
std::string configline;
std::map<std::string,std::string> configuration;
read_configuration(config,configuration);
config.close();
@ @<Check the configuration of \.{rss-reader}@>=
check_config("wgeturl",configuration,"URL to retrieve");
check_config("wgetpath",configuration,"URL to retrieve");
check_config("verbosity",configuration,"Verboseness of bot");
wget_process::wgeturl = configuration[std::string("wgeturl")];
wget_process::wgetpath = configuration[std::string("wgetpath")];
wget_process::verbosity = atoi(configuration[std::string("verbosity")].c_str());
void (wget_process::*pmf)();
auto rt = configuration.find(std::string("rss_time"));
if(rt == configuration.end())
	pmf = &wget_process::fix_time;
else {
	wget_process::maxpubtime = atoi(rt->second.c_str());
	pmf = &wget_process::queue_messages;
}
@ @<Global variable declarations for \.{rss-reader}@>=
const char* wget_argv[] = { "wget", 0, "-q", "-O", "-", 0 };
@ @<Read the RSS feed@>=
wget_argv[1] = const_cast<char*>(wget_process::wgeturl.c_str());
std::vector<const char*> wgetv;
for(const char** wpp = &wget_argv[0]; *wpp; ++wpp)
	wgetv.push_back(*wpp);
wget_process wp(wgetv);
bool pf = wp.process_feed();
if(pf)
	(wp.*pmf)();
@ @<Write the time value@>=
if(pf) {
	config.open(configfilename,std::ios_base::out|std::ios_base::trunc);
	for(auto p = configuration.begin(); p != configuration.end(); ++p)
		if(p->first != "rss_time")
			config << p->first << '\t' << p->second << std::endl;
	config << "rss_time" << '\t' << wget_process::maxpubtime << std::endl;
	config.close();
}
@ @<Header inclusions for \.{rrs-reader}@>=
#include <cstring>
#include <cstdlib>
#include <unistd.h>
#include "gitirc-logger.h"
#include <string>
#include <map>
#include "gitirc-read_configuration.h"
#include "gitirc-check_config.h"
#include "gitirc-wget_process.h"
@ @<Global variable declarations for \.{rss-reader}@>=
gitirc_logger userlog;
