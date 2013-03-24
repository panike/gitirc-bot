@
@s std int
@s string int
@(gitirc-get_sha1.h@>=
#ifndef GITIRC_GET_SHA1_H
#define GITIRC_GET_SHA1_H
#include <string>
std::string get_sha1(const std::string& s)
{
	return s.substr(0,40);
}
#endif // |GITIRC_GET_SHA1_H|
