@ A logging class to get the dates prefixed for an event
@(gitirc-logger.h@>=
#ifndef _GITIRC_LOGGER_H
#define _GITIRC_LOGGER_H
#include <fstream>
class gitirc_logger : public std::ofstream {
public:
	friend std::ostream& operator<<(gitirc_logger& s, const char* t);
	friend std::ostream& operator<<(gitirc_logger& s, char t);
	std::ostream& get_stream();
	static const char* get_time();
private:
	static char ts[64];
};
#endif
@ @c
#include "gitirc-logger.h"
#include <time.h>
char gitirc_logger::ts[64];
const char* gitirc_logger::get_time()
{
	time_t tt;
	time(&tt);
	strftime(gitirc_logger::ts,64,"%F %T: ", localtime(&tt));
	return gitirc_logger::ts;
}
@ @c
std::ostream& operator<<(gitirc_logger& s, const char* t)
{
	std::ostream& os = static_cast<std::ostream&>(s) << gitirc_logger::get_time() << t;
	if(!os) _exit(1);
	return os;
}
@ @c
std::ostream& operator<<(gitirc_logger& s, char t)
{
	std::ostream& os = static_cast<std::ofstream&>(s) << gitirc_logger::get_time() << t;
	if(!os) _exit(1);
	return os;
}
@ @c
std::ostream& gitirc_logger::get_stream()
{
	return *this;
}

