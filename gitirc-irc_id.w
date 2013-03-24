@
@s std int
@s string int
@(gitirc-irc_id.h@>=
#ifndef GITIRC_IRC_ID_H
#define GITIRC_IRC_ID_H
#include <string>
struct irc_id {
	std::string to_whom,msg;
	irc_id(const std::string& w,const std::string& m) : to_whom(w),msg(m) {}
	irc_id(const std::string& m) : to_whom(),msg(m)@+{}
	irc_id(std::string&& m) : to_whom(),msg(m)@+{}
};
#endif // |GITIRC_IRC_ID_H|
