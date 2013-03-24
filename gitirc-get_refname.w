@s std int
@s string int
@ @(gitirc-get_refname.h@>=
#ifndef GITIRC_GET_REFNAME_H
#define GITIRC_GET_REFNAME_H
#include <string>
#include <algorithm>
std::string get_refname(const std::string& s)
{
	auto si = std::find(s.rbegin(),s.rend(),'\t');
	if(si == s.rend()) return std::string();
	auto sif = si.base();
	return std::string(sif,s.end());
}
#endif // |GITIRC_GET_REFNAME_H|
