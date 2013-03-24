@s istream int
@s std int
@s string int
@s map int
@ @(gitirc-read_configuration.h@>=
#ifndef GITIRC_READ_CONFIGURATION_H
#define GITIRC_READ_CONFIGURATION_H
#include <fstream>
#include <map>
#include <string>
void read_configuration(std::istream& is,std::map<std::string,std::string>& configuration);
void dump_configuration(const std::map<std::string,std::string>&);
#endif
@ @c
#include "gitirc-read_configuration.h"
#include "gitirc-logger.h"
#include <unistd.h>
extern gitirc_logger userlog;
void read_configuration(std::istream& is,std::map<std::string,std::string>& configuration)
{
	std::string configline;
	while(std::getline(is,configline)){
		size_t tpos = configline.find('\t');
		if(tpos == std::string::npos){
			userlog << "A configuration line should be a pair, separated by a "
			"tab" << std::endl;
			::_exit(1);
		}
		std::string configoption = configline.substr(0,configline.find('\t'));
		std::string configvalue = configline.substr(configline.rfind('\t')+1);
		configuration[configoption] = configvalue;
	}	
}
@ @c
void dump_configuration(const std::map<std::string,std::string>& configuration)
{
	for(std::map<std::string,std::string>::const_iterator it = configuration.begin();
			it != configuration.end(); ++it)
		userlog << it->first << " = " << it->second << std::endl;	
}
