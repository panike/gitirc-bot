@s std int
@s list int
@s string int
@s map int
@ @(gitirc-irc_ctx.h@>=
#ifndef GITIRC_IRC_CTX_H
#define GITIRC_IRC_CTX_H
#include <list>
#include <map>
#include <string>

class git_db;
class irc_id;
struct irc_ctx {
	std::list<irc_id>& messages;
	std::map<std::string,std::string>& configuration;
	const std::string schannel;
	const std::string snick;
	git_db* repo;
	bool saw366event;
	irc_ctx(std::list<irc_id>& m, std::map<std::string,std::string>& c)
		: messages(m), configuration(c), schannel("channel"),
		snick("nick"), repo(0), saw366event(false)@+{}
};
#endif // |GITIRC_IRC_CTX_H|
