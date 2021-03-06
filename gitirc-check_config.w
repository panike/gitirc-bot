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
@ @(gitirc-check_config.h@>=
#ifndef GITIRC_CHECK_CONFIG_H
#define GITIRC_CHECK_CONFIG_H
#include <string>
#include <map>
void check_config(const char* p,std::map<std::string,std::string>& cfg,const char* msg);
#endif //|GITIRC_CHECK_CONFIG_H|
@
@s iterator int
@c
#include "gitirc-check_config.h"
#include "gitirc-logger.h"
#include <iostream>
#include <unistd.h>
extern gitirc_logger userlog;
void check_config(const char* p,std::map<std::string,std::string>& cfg,const char* msg)
{
	auto s = cfg.find(std::string(p));
	if(s == cfg.end() || s->second.size() == 0){
		userlog << msg << std::endl;
		userlog << p << "\\t<" << p << ">" << std::endl;
		userlog.flush();
		::_exit(1);
	}
}
