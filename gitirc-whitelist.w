@ This is a program to handle whitelist given in CIDR notation
for the bot
@(gitirc-whitelist.h@>=
#include <vector>
#include <string>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/ip.h>

class whitelist {
public:
	bool insert(const std::string&s);
	bool accept(struct in_addr ia) const;
private:
	struct node {
		u_int32_t addr;
		u_int32_t mask;	
		node() : addr(0), mask(0) {}
	};
	std::vector<node> allowed;
};
@ We insert the string, and the code inserts a rule into the |allowed| vector
if we want to accept the connection.
The string here should look like a plain IP address: ``\.{x.x.x.x}'' or a
CIDR address: ``\.{x.x.x.x/mask}''.
@ @c
#include "gitirc-whitelist.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <algorithm>
#include "gitirc-logger.h"
#if 0
#include <iomanip>
#include <iostream>
#endif
@ @c
extern gitirc_logger userlog;
@ @c
bool whitelist::insert(const std::string&s)
{
	std::string::const_iterator p = std::find(s.begin(),s.end(),'/');
	std::string address(s.begin(),p);
	struct in_addr ip;
	userlog << "Inserting " << s << " into whitelist" << std::endl;
	if(!inet_aton(address.c_str(),&ip)) {
		userlog << "Failed to read ip address in string \"" << s << "\"" << std::endl;
		return false;
	}
	node n;
	n.addr = ip.s_addr;
	if(p == s.end()) n.mask = ~0;
	else {
		++p;
		u_int32_t count_mask_bits = 0;
		for(;p!=s.end();++p) {
			if(!std::isdigit(*p)) break;
			count_mask_bits *= 10;
			count_mask_bits += *p - '0';
		}
		if(count_mask_bits >= 32) n.mask = ~0;
		else n.mask = ((1<<count_mask_bits)-1)<<(32-count_mask_bits);
		n.mask=htonl(n.mask);
	}
	allowed.push_back(n);
	return true;
}
@ By default, if there is no whitelist, we accept from everybody.
@c
bool whitelist::accept(struct in_addr ia) const
{
	if(allowed.empty()) return true;
	for(auto p = allowed.begin(); p != allowed.end(); ++p) {
#if 0
		std::cerr << "Input:   " << std::setw(8) << std::setfill('0') << std::setbase(16)
			<< ia.s_addr << std::endl;
		std::cerr << "Allowed: " << std::setw(8) << std::setfill('0') << std::setbase(16)
			<< p->addr << std::endl;
		std::cerr << "Mask:    " << std::setw(8) << std::setfill('0') << std::setbase(16)
			<< p->mask << std::endl;
#endif
		if((ia.s_addr & p->mask) == (p->addr & p->mask))
			return true;
	}
	return false;
}
@ @(gitirc-whitelist-test.cpp@>=
#include "gitirc-logger.h"
#include "gitirc-whitelist.h"
#include <iostream>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
gitirc_logger userlog;

int main(int argc,char* argv[])
{
	userlog.open("gitirc-whitelist-test.out");
	whitelist w;
	w.insert("127.0.0.1");
    w.insert("204.232.175.64/27");
    w.insert("192.30.252.0/22");
	struct in_addr ip;
	inet_aton("127.0.0.1",&ip);
	if(!w.accept(ip)) {
		std::cerr << "Failed to accept 127.0.0.1" << std::endl;
		return 1;
	}
	inet_aton("192.30.252.54",&ip);
	if(!w.accept(ip)) {
		std::cerr << "Failed to accept 192.30.252.54" << std::endl;
		return 1;
	}
	return 0;
}
