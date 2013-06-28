@q This file defines standard C++ namespaces and classes @>
@q Please send corrections to saroj-tamasa@@worldnet.att.net @>
@s JSON int
@s Process int
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
@s const_iterator int
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
@s gitirc_logger int
@s unary_function make_pair
@s unary_function int
@ This program watches a git repository and reports changes to an IRC channel.
@s irc_id int
@s git_db int
@c
@<Header inclusions for |main|@>@;
namespace {
@<Variable declarations for |main|@>@;
@<Function declarations for |main|@>@;
}
namespace gitirc_constants {
@<Constants for expressiveness and templating@>@;
};
@<Helper class definitions@>@;
@ @c
int main(int argc,char* argv[],char* envp[])
{
	@<Close all file descriptors and the terminal@>@;
	@<Get |userlogname| from command line@>@;
	@<Print start message@>@;
	whitelist http_whitelist;
	@<Deal with the configuration@>@;
	std::list<irc_id> messages;
	std::string schannel("channel");
	@<Initialize the program@>@;
	int acceptfd = gitirc_constants::invalid_fd;
	for(;;){
		bool need_to_read_repo = true;
		@<Connect to irc server@>@;
		userlog << "OK, we are connected now" << std::endl;
		while(irc_is_connected(ist)) @<Busy wait until the channel is ready for us@>@;
		std::string abuf;
		struct timeval last_message_time;
		last_message_time.tv_sec = last_message_time.tv_usec = 0;
		while(irc_is_connected(ist)) {
			if(!messages.empty())
				@<If we have something to write to the channel, write it@>@;
			if(messages.empty() && need_to_read_repo) {
				@<Watch the references@>@;
				@<Check in with gittrac@>@;
				need_to_read_repo = false;
			}
			@<Wait for something to happen@>@;
			@<Check for configuration changes@>@;
		}
		irc_destroy_session(ist);
	}
	@<Clean up after ourselves@>@;
	return 0;
}
@ @<Declare |userlog|@>=
gitirc_logger userlog;
@ The lines we send can be at most 384 characters long.  We refuse to send any
message that is longer than 2000 characters.
@<Constants for expressiveness and templating@>=
const int invalid_fd = -1;
const unsigned int max_irc_line_len = 384;
const unsigned int max_irc_msg_size = 2000;
const unsigned int max_irc_line_with_cushion = 380;
@ @<Helper class definitions@>=
namespace {
	struct spaceFinder : std::unary_function<char,bool> {
		bool operator()(char ch) const { return isspace(ch); }
	};
}
@ @<Helper class definitions@>=
namespace {
class StringSplitter {
public:
	StringSplitter(const std::string& s,unsigned int length);
	operator bool()@+{@+return !source.empty();@+}
	std::string get();
private:
	StringSplitter();
	std::string source;
	unsigned int len;
};
}
@ @<Helper class definitions@>=
StringSplitter::StringSplitter(const std::string& s, unsigned int length) :
		source(s), len(length) {
	trim_boundary_space(source);
}
@ @<Helper class definitions@>=
@<Declare |userlog|@>@;
std::string StringSplitter::get()
{
	std::string ret;
	if(source.size() <= len)
		std::swap(ret,source);
	else @<The string needs to be split into smaller pieces@>@;
	return ret;
}
@ @<The string needs to be split into smaller pieces@>={
	auto p = source.rend() - len;
	if((p = std::find_if(p,source.rend(),spaceFinder())) == source.rend()) {
		ret = source.substr(0,len);
		source = source.substr(len);
	}@+else {
		auto q = std::find_if(p,source.rend(),std::not1(spaceFinder()));
		ret.assign(source.begin(),q.base());
		source.erase(source.begin(),p.base());
	}
}
@ @<If we have something to write to the channel, write it@>={
	struct timeval tt;
	::gettimeofday(&tt,0);
	struct timeval delta_tt = subtract_time(tt,last_message_time);
	if(delta_tt.tv_sec > 2 || (delta_tt.tv_sec == 2 && delta_tt.tv_usec > 200000)) {
		auto p = messages.begin();
		std::string recipient=(!p->to_whom.empty())?p->to_whom:configuration[schannel];
		std::string message = p->msg;
		messages.erase(p);
		trim_boundary_space(message);
		if(!message.empty()) {
			if(message.size() < gitirc_constants::max_irc_line_len) {
				irc_cmd_msg(ist,recipient.c_str(),message.c_str());
				last_message_time = tt;
			}@+else if(message.size() < gitirc_constants::max_irc_msg_size)
				@<Split the message into parts of around 380 chars@>@;
			else userlog << "Message too long to send to channel" << std::endl;
			if(message.size() < gitirc_constants::max_irc_line_len)
				userlog << "Sent to " << recipient << " \"" << message
					<< '"' << std::endl;
		}
	}
}
@ @<Function declarations for |main|@>=
struct timeval subtract_time(const struct timeval& tt, const struct timeval& oldt);
@ @c
namespace {
struct timeval subtract_time(const struct timeval& tt, const struct timeval& oldt)
{
	struct timeval ret;
	int usdiff = tt.tv_usec - oldt.tv_usec;
	int sdiff = tt.tv_sec - oldt.tv_sec;
	if(usdiff < 0) {
		--sdiff;
		usdiff += 1000000;
	}
	ret.tv_sec = sdiff;
	ret.tv_usec = usdiff;
	return ret;
}}
@ @<Function declarations for |main|@>=
void trim_boundary_space(std::string& message);
@ @c
namespace {
void trim_boundary_space(std::string& message)
{
	auto mri = std::find_if(message.rbegin(),message.rend(),
		std::not1(spaceFinder()));
	message.erase(mri.base(),message.end());
	auto mit = std::find_if(message.begin(),message.end(),
		std::not1(spaceFinder()));
	message.erase(message.begin(),mit);
}}
@ @<Split the message into parts of around 380 chars@>={
	StringSplitter ssp(message,gitirc_constants::max_irc_line_with_cushion);
	std::list<irc_id> top_list;
	while(ssp) top_list.push_back(irc_id(recipient,ssp.get()));
	p = top_list.begin();
	message = p->msg;
	top_list.erase(p);
	messages.insert(messages.begin(),top_list.begin(),top_list.end());
	trim_boundary_space(message);
	if(!message.empty()) {
		irc_cmd_msg(ist,recipient.c_str(),message.c_str());
		last_message_time = tt;
	}
}
@ @<Get |user...@>=
const char* userlogname = 0;
for(int i=1;i<argc;++i)
	if(!strcmp(argv[i],"-l"))
		userlogname = argv[++i];
if(!userlogname)
	userlogname = "gitirc.log";
userlog.open(userlogname,std::ios_base::out|std::ios_base::ate|std::ios_base::app);
@ @<Clean up...@>=
userlog.close();
@ When we fork, we do not want anything going to the terminal.
@s rlimit int
@<Close all file desc...@>=
struct rlimit rlim;
getrlimit(RLIMIT_NOFILE,&rlim);
ioctl(0,TIOCNOTTY);
for(unsigned int i=0;i<rlim.rlim_cur;++i)
	::close(i);
open("/dev/null",O_RDONLY);
open("/dev/null",O_WRONLY);
open("/dev/null",O_WRONLY);
if(fork())
	::_exit(0);
@ @<Print start message@>=
if(!userlog)
	::_exit(1);
for(int i=0;i<gitirc_constants::normal_log_line_length;++i)
	userlog.get_stream() << '*';
userlog.get_stream() << std::endl;
userlog << "Log starting now" << std::endl;
userlog << "Pid is " << getpid() << std::endl;
userlog << "gitirc version is " << gitirc_BUILD_STRING << std::endl;
@ @<Constants for expressiveness and templating@>=
const int normal_log_line_length = 72;
@ @<Deal with the configuration@>=
@<Get the configuration file@>@;
@<Read the configuration file@>@;
@<Check the configuration@>@;
if(!configuration["directory"].empty())
	chdir(configuration["directory"].c_str());
get_outputs(configuration);
@<Configure the whitelist@>@;
@ @<Function declarations for |main|@>=
void get_outputs(std::map<std::string,std::string>& c)
{
	auto ci = c.find("error");
	if(ci != c.end()) {
		::close(2);
		::open(ci->second.c_str(),O_CREAT|O_APPEND|O_WRONLY,S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH);
	}
	ci = c.find("output");
	if(ci != c.end()) {
		::close(1);
		::open(ci->second.c_str(),O_CREAT|O_APPEND|O_WRONLY,S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH);
	}
}
@ @<Get the configuration file@>=
char* configfilename = 0;
for(int i=1;i<argc;++i)
	if(!strcmp(argv[i],"-c")){
		configfilename = argv[++i];
		break;
	}
if(!configfilename)
	usage(argv[0]);
@ @<Get the configuration file@>=
time_t conf_mtime = 0;
if(configfilename) {
	struct stat cf;
	if(!::stat(configfilename,&cf))
		conf_mtime = cf.st_mtime;
}
@ @<Check for configuration changes@>=
if(configfilename) {
	struct stat cf;
	if(!::stat(configfilename,&cf) && cf.st_mtime > conf_mtime) {
		conf_mtime = cf.st_mtime;	
		configfile.open(configfilename,std::ios::in);
		read_configuration(configfile,configuration);
		configuration["config"] = configfilename;
		dump_configuration(configuration);
		git_db new_repo(configuration,false);
		the_repo = new_repo;
		configfile.close();
	}
}
@ @<Function declarations for |main|@>=
void usage(const char* s);
@ @c
namespace {
void usage(const char* s)
{
	userlog << "Usage: " << s << " <-c configfile> [-l <logfilename>]" << std::endl;
	userlog << "logfilename defaults to \"gitirc.log\"." << std::endl;
	::_exit(1);
}
}
@ @<Read the configuration file@>=
std::fstream configfile(configfilename,std::ios::in);
std::map<std::string,std::string> configuration;
configuration["config"] = configfilename;
read_configuration(configfile,configuration);
dump_configuration(configuration);
configfile.close();
Process::envp = envp;
std::string logname = configuration["log"];
@ @<Check the config...@>=
check_config("gitpath",configuration,"Need path to git");
check_config("gitrepo",configuration,"Need path to the repository");
check_config("log",configuration,"Need a logfile to hold references");
@ @<Watch the references@>=
std::list<irc_id> tmessages = the_repo.update();
if(!tmessages.empty()) {
	std::string newlogname(logname);
	newlogname.append(".new");
	std::ofstream logdump(newlogname.c_str(),std::ios_base::out | std::ios_base::trunc);
	bool success=true;
	if(logdump) {
		for(auto mi = the_repo.get_refs().begin(); mi != the_repo.get_refs().end(); ++mi) {
			if(!logdump) {
				success = false;
				break;
			}	
			logdump << mi->second << "\t" << mi->first << std::endl;
		}
	}@+else success = false;
	logdump.close();
	if(success) {
		userlog << "Inserting new refs into " << logname << std::endl;
		if(::rename(newlogname.c_str(),logname.c_str())) {
			userlog << "Failed to rename" << std::endl;
			_exit(1);
		}
	}@+else {
		userlog << "Failed to write refs into " << logname << std::endl;
		userlog << "Will try again next time" << std::endl;
		if(::unlink(newlogname.c_str()))
			userlog << "Failed to unlink " << newlogname << std::endl;
		_exit(1);
	}	
}
#if 0
for(auto tmsg = tmessages.begin(); tmsg != tmessages.end(); ++tmsg)
	userlog << "Message is \"" << tmsg->msg << "\"" << std::endl;
#endif
messages.insert(messages.begin(),tmessages.begin(),tmessages.end());
@ We rotate the log after 16 megabytes has been used.
@<Wait for something to happen@>=
if(userlog.tellp() > gitirc_constants::log_rotation_limit) {
	userlog << "Reached rotation limit.  Changing to a new file" << std::endl;
	userlog.close();
	std::string newuserlog(userlogname);
	newuserlog += ".old";
	::unlink(newuserlog.c_str());
	::rename(userlogname,newuserlog.c_str());
	userlog.open(userlogname,std::ios_base::out|std::ios_base::trunc);
	userlog << "Reached rotation limit. Now writing into new file" << std::endl;
	@<Print start message@>@;
}
@ This use of timeval is not portable, according to the |select|(2) manual
page.
@s fd_set int
@s timeval int
@<Wait for something to happen@>=
struct timeval tv;
if(acceptfd < 0 && messages.empty()) {
	tv.tv_sec=gitirc_constants::sleep_for_one_hour;
	tv.tv_usec=0;
}@+else {
	tv.tv_sec=gitirc_constants::inter_message_sleep_time_sec;
	tv.tv_usec=gitirc_constants::inter_message_sleep_time_usec;
}
@ @<Wait for something to happen@>=
while(acceptfd >= 0 || tv.tv_sec > 0 || tv.tv_usec > 0){
	@<Set up the select system call@>@;
	@<Check |listenfd| for pokes@>@;
	@<Check |buildfd| for messages@>@;
	@<Check |http_socket| for messages@>@;
	if(http_msg_complete) {
		@<Process http message@>@;
		http_msg_complete = false;
		http_message.clear();
	}
done_processing_http:
	if(!messages.empty() || need_to_read_repo) break;
}
@ @<Set up the select system call@>=
int maxfd = (listenfd>buildfd)?listenfd:buildfd;
fd_set rfds,wfds;
maxfd = (acceptfd>maxfd)?acceptfd:maxfd;
maxfd = (http_socket > maxfd)?http_socket:maxfd;
maxfd = (httpfd>maxfd)?httpfd:maxfd;
FD_ZERO(&rfds);
FD_ZERO(&wfds);
FD_SET(listenfd,&rfds);
if(acceptfd >= 0) FD_SET(acceptfd,&rfds);
else FD_SET(buildfd,&rfds);
if(httpfd >= 0) FD_SET(httpfd,&rfds);
else FD_SET(http_socket,&rfds);
irc_add_select_descriptors(ist,&rfds,&wfds,&maxfd);
::select(maxfd+1,&rfds,&wfds,0,&tv);
irc_process_select_descriptors(ist,&rfds,&wfds);
@ @<Check |buildfd| for messages@>=
if((acceptfd >= 0 && FD_ISSET(acceptfd,&rfds)) || FD_ISSET(buildfd,&rfds)){
	if(acceptfd < 0 && FD_ISSET(buildfd,&rfds))
		acceptfd = ::accept(buildfd,0,0);
	if(acceptfd>=0){
		for(;;) @<Read from |acceptfd| without blocking@>@;
		if(!abuf.empty()) {
			messages.push_back(irc_id(abuf));
			abuf.clear();
		}
	}
}
@ @<Read from |acceptfd| without blocking@>={
	@<See if we would block in reading |acceptfd|@>@;
	char buf[gitirc_constants::max_irc_line_len];
	int aread = ::read(acceptfd,buf,gitirc_constants::max_irc_line_len);
	if(aread == 0) {
		::close(acceptfd);
		acceptfd = gitirc_constants::invalid_fd;
		break;
	}
	@<Push our characters into |abuf|@>@;
}
@ @<Check |listenfd| for pokes@>=
if(FD_ISSET(listenfd,&rfds)){
	int afd = ::accept(listenfd,0,0);
	need_to_read_repo = true;
	if(afd >= 0){
		::shutdown(afd,SHUT_RDWR);
		::close(afd);
		time_t now;
		::time(&now);
		if(messages.empty() && now > last_build_check_time + 3600)
			last_build_check_time = now;
		break;
	}
}
@ @<Push our characters into |abuf|@>=
for(int ii=0; ii<aread;) {
	auto aend = std::find(&buf[ii],&buf[aread],'\0');
	aend = std::find(&buf[ii],aend,'\n');
	if(aend == &buf[aread]) {
		abuf.append(&buf[ii],&buf[aread]);
		break;
	}@+else if(aend == &buf[ii]) ++ii;
	else {
		abuf.append(&buf[ii],aend);
		messages.push_back(irc_id(abuf));
		abuf.clear();
		ii = std::distance(&buf[0],aend) + 1;
	}
}
@ @<See if we would block in reading |acceptfd|@>=
fd_set afds;
FD_ZERO(&afds);
FD_SET(acceptfd,&afds);
struct timeval tva;
tva.tv_sec = 0;
tva.tv_usec = 0;
if(::select(acceptfd+1,&afds,0,0,&tva) == 0) break;
@ @<Initialize the program@>=
git_db the_repo(configuration);
time_t last_build_check_time;
::time(&last_build_check_time);
the_repo.fetch();
@ @<Initialize the program@>=
@<Initialize libircclient@>@;
@<Set up the listening socket@>@;
@ @<Constants for expressiveness and templating@>=
const int log_rotation_limit = (1<<24);
const int sleep_for_one_hour = 3600;
const int inter_message_sleep_time_sec = 2;
const int inter_message_sleep_time_usec = 200000;
@*Using libircclient. The libircclient library seems like a good candidate for
this application.
@s irc_callbacks_t int
@s irc_session_t int
@s irc_dcc_t int
@<Initialize lib...@>=
irc_callbacks_t irc;
memset(&irc,'\0',sizeof(irc_callbacks_t));
irc.event_connect = handle_connect_msg;
irc.event_nick = 0;
irc.event_quit = 0;
irc.event_join = 0;
irc.event_part = 0;
irc.event_mode = 0;
irc.event_umode = dump_event;
irc.event_topic = 0;
irc.event_kick = dump_event;
irc.event_notice = dump_event;
irc.event_invite = dump_event;
irc.event_unknown = dump_event;
irc.event_ctcp_action = dump_event;
irc.event_channel = process_privmsg<true>;
irc.event_privmsg = process_privmsg<false>;
irc.event_numeric = dump_code_event;
irc.event_dcc_chat_req = handle_dcc_chat_msg;
irc.event_dcc_send_req = handle_dcc_send_msg;
@ @<Function declarations for |main|@>=
void dump_event(irc_session_t*,const char*,const char*,const char**,unsigned int);
template<bool is_channel>
void process_privmsg(irc_session_t*,const char*,const char*,const char**,unsigned int);
void dump_code_event(irc_session_t*,unsigned int,const char*,const char**,unsigned int);
void handle_connect_msg(irc_session_t*, const char *,
	const char *, const char **, unsigned int) {}
void handle_dcc_chat_msg(irc_session_t *session, const char *nick,
	const char *addr, irc_dcc_t dccid);
void handle_dcc_send_msg(irc_session_t *session, const char *nick,
	const char *addr, const char *filename, unsigned long size,
	irc_dcc_t dccid);
@ @c
namespace {
void dump_event(irc_session_t*session,const char*event,const char*origin,
	const char**params, unsigned int count)
{
	userlog << "Event: " << event;
	if(origin) userlog.get_stream() << " Origin: " << origin;
	for(unsigned int i=0;i<count;++i)
		userlog.get_stream() << " params(" << i << "): " << params[i];
	userlog.get_stream() << std::endl;
	userlog.flush();
}
}
@ @<Constants for expressiveness and templating@>=
const int default_strftime_len = 64;
@
@s push_into_ctx make_pair
@s process_privmsg make_pair
@c
namespace {
template<bool is_channel_msg>
void process_privmsg(irc_session_t*session,const char*event,const char*origin,
		const char**params, unsigned int count)
{
	dump_event(session,event,origin,params,count);
	if(params[1]) {
		std::string result;
		std::string privmsg(params[1]);
		auto it = privmsg.begin();
		while(it != privmsg.end())
			@<Find and act on a command@>@;
	}
}
}
@ @<Find and act on a command@>={
	@<Check to see if we have a command@>@;
	if(ref.find("branchcontains:") == 0)
		@<Run \.{git branch --contains} for the ref@>@;
	else if(ref.find("tagcontains:") == 0)
		@<Run \.{git tag --contains} for the ref@>@;
	else if(ref.find("build:") == 0)
		@<Output a url corresponding to the commit@>@;
	else if(ref.find("ticket:") == 0)
		@<Output a url for the corresponding ticket number@>@;
	else if(ref.find("parents:") == 0)
		@<List the parents of a commit@>@;
	else if(ref.find("children:") == 0)
		@<List the children of a commit@>@;
	else if(ref.find("shutup")==0)
		@<Flush the message queue@>@;
	else @<Hopefully it is a commit.  Print the log subject line@>@;
	if(!result.empty())
		push_into_ctx<is_channel_msg>(static_cast<irc_ctx*>(irc_get_ctx(session)),
			result,origin);
}
@ @<Flush the message queue@>={
	irc_ctx* p = static_cast<irc_ctx*>(irc_get_ctx(session));
	if(p) p->messages.clear();
}
@ @<Check to see if we have a command@>=
it = std::find(it,privmsg.end(),'!');
if(it == privmsg.end() || ++it == privmsg.end()) break;
auto p = std::find_if(it,privmsg.end(),spaceFinder());
if((p = std::find(it,p,'!')) == it) continue;
std::string ref(it,p); // Should be a string with no spaces and no `!'
@ @<Function declarations for |main|@>=
template<bool is_channel>
void push_into_ctx(irc_ctx* ctx,const std::string& result,
	const char* tonick);
@ @c
namespace {
template<>
void push_into_ctx<true>(irc_ctx* ctx,const std::string& refname,
	const char*)
{
	std::string nickname;
	auto pp = ctx->configuration.find(ctx->schannel);
	if(pp != ctx->configuration.end())
		nickname = pp->second;
	if(!nickname.empty())
		ctx->messages.push_back(irc_id(nickname,refname));
}
}
@ @c
namespace {
template<>
void push_into_ctx<false>(irc_ctx* ctx,const std::string& refname,
	const char* tonick)
{
	char nick[gitirc_constants::max_nick_name];
	irc_target_get_nick(tonick,nick,gitirc_constants::max_nick_name);
	nick[gitirc_constants::max_nick_offset]='\0';
	std::string nickname(nick);
	if(!nickname.empty())
		ctx->messages.push_back(irc_id(nickname,refname));
}
}
@ @<Constants for expressiveness and templating@>=
const int max_nick_name = 64;
const int max_nick_offset = max_nick_name - 1;
@ @<Run \.{git branch --contains} for the ref@>={
	irc_ctx* icp = static_cast<irc_ctx*>(irc_get_ctx(session));
	if(!icp) continue;
	std::string refname(std::find(ref.begin(),ref.end(),':')+1,ref.end());
	if(refname.empty() || !icp->repo->check_is_commit(refname)) continue;
	result = icp->repo->contains(refname,"branch");
}
@ @<List the parents of a commit@>={
	irc_ctx* icp = static_cast<irc_ctx*>(irc_get_ctx(session));
	if(!icp) continue;
	std::string refname(std::find(ref.begin(),ref.end(),':')+1,ref.end());
	if(refname.empty() || !icp->repo->check_is_commit(refname)) continue;
	result = icp->repo->get_parents(refname);
}
@ @<List the children of a commit@>={
	irc_ctx* icp = static_cast<irc_ctx*>(irc_get_ctx(session));
	if(!icp) continue;
	std::string refname(std::find(ref.begin(),ref.end(),':')+1,ref.end());
	if(refname.empty() || !icp->repo->check_is_commit(refname)) continue;
	result = icp->repo->get_children(refname);
}
@ @<Run \.{git tag --contains} for the ref@>={
	irc_ctx* icp = static_cast<irc_ctx*>(irc_get_ctx(session));
	if(!icp) continue;
	std::string refname(std::find(ref.begin(),ref.end(),':')+1,ref.end());
	if(refname.empty() || !icp->repo->check_is_commit(refname)) continue;
	result = icp->repo->contains(refname,"tag");
}
@ @<Output a url corresponding to the commit@>={
	irc_ctx* icp = static_cast<irc_ctx*>(irc_get_ctx(session));
	if(!icp) continue;
	std::string refname(std::find(ref.begin(),ref.end(),':')+1,ref.end());
	if(refname.empty() || !icp->repo->check_is_commit(refname)) continue;
	result = icp->repo->get_build_url(refname,true);
}
@ @<Output a url for the corresponding ticket number@>={
	std::string tkt(std::find(ref.begin(),ref.end(),':')+1,ref.end());
	std::string::iterator it = tkt.begin();
	while(it != tkt.end()) {
		if(!isdigit(*it))
			break;
		++it;
	}
	if(it != tkt.end()) continue;
	if(irc_ctx* icp = static_cast<irc_ctx*>(irc_get_ctx(session))) {
		std::map<std::string,std::string>::iterator mit = icp->configuration.find("ticket_prefix");
		if(mit != icp->configuration.end()) {
			result = mit->second;
			if(!result.empty()) result.append(tkt);
		}
	}
}
@ @<Hopefully it is a commit.  Print the log subject line@>={
	std::stringstream mm;
	irc_ctx* icp = static_cast<irc_ctx*>(irc_get_ctx(session));
	if(!icp) continue;
	if(ref.empty() || !icp->repo->check_is_commit(ref)) continue;
	result = icp->repo->get_single_ref<true>(ref);
	if(!result.empty()) {
		mm << ref << ": " << result;
		result = mm.str();
	}
}
@ @c
namespace {
void dump_code_event(irc_session_t*session,unsigned int event,const char*origin,
	const char**params,unsigned int count)
{
	userlog << "Event: " << event << " Origin: " << origin;
	for(unsigned int i=0;i<count;++i)
		userlog.get_stream() << " params(" << i << "): " << params[i];
	userlog.get_stream() << std::endl;
	userlog.flush();
	if(event == 366) {
		struct irc_ctx* icp = static_cast<irc_ctx*>(irc_get_ctx(session));
		icp->saw366event = true;
	}
}
}
@ @c
namespace {
void handle_dcc_chat_msg(irc_session_t *session, const char *,
	const char *, irc_dcc_t dccid)
{
	irc_dcc_decline(session,dccid);
}
}
@ @c
namespace {
void handle_dcc_send_msg(irc_session_t *session, const char *,
	const char * , const char *, unsigned long, irc_dcc_t dccid)
{
	irc_dcc_decline(session,dccid);
}
}
@
@s irc_ctx int
@<Check the config...@>=
check_config("server",configuration,"Need a server name");
check_config("port",configuration,"Need a port");
check_config("nick",configuration,"Need a nick");
check_config("username",configuration,"Need a username");
check_config("realname",configuration,"Need a realname");
@ @<Connect to irc server@>=
irc_session_t* ist = irc_create_session(&irc);
if(!ist){
	userlog << "Could not create an IRC session!" << std::endl;
	::_exit(1);
}
@ @<Connect to irc server@>=
irc_ctx myctx(messages,configuration);
myctx.repo = &the_repo;
irc_set_ctx(ist,&myctx);
@ @<Connect to irc server@>=
int connection_count = 0;
while(irc_connect(ist,configuration["server"].c_str(),
		atoi(configuration["port"].c_str()), 0,
		configuration["nick"].c_str(),
		configuration["username"].c_str(),
		configuration["realname"].c_str())) {
	struct timeval tv;
	userlog << "Error message: " << irc_strerror(irc_errno(ist)) << std::endl;
	tv.tv_sec = gitirc_constants::reconnect_sleep_time;
	tv.tv_usec = 0;
	userlog << "Could not connect to the server." << std::endl;
	select(0,0,0,0,&tv);
	if(++connection_count >= gitirc_constants::maximum_connection_attempts) ::_exit(1);
}
@ @<Busy wait until the channel is ready for us@>={
	int m=0;
	fd_set rfds,wfds;	
	FD_ZERO(&rfds);
	FD_ZERO(&wfds);
	irc_add_select_descriptors(ist,&rfds,&wfds,&m);
	select(m+1,&rfds,&wfds,0,0);
	irc_process_select_descriptors(ist,&rfds,&wfds);
	struct irc_ctx* icp = static_cast<irc_ctx*>(irc_get_ctx(ist));
	if(icp->saw366event) break;
}
@ @<Constants for express...@>=
const int reconnect_sleep_time = 5;
const int maximum_connection_attempts = 5;
@ @<Check the config...@>=
check_config("channel",configuration,"Need a channel name");
@ @<Connect to irc server@>=
fd_set rfds,wfds;
FD_ZERO(&rfds);
FD_ZERO(&wfds);
int maxfd;
irc_add_select_descriptors(ist,&rfds,&wfds,&maxfd);
select(maxfd+1,&rfds,&wfds,0,0);
irc_process_select_descriptors(ist,&rfds,&wfds);
if(irc_cmd_join(ist,configuration["channel"].c_str(),0)){
	userlog << "Could not join the channel!" << std::endl;
	::_exit(1);
}
@*The listening sockets. We do not take any input on this socket; we just bind,
and wait for clients to connect.
@s sockaddr_in int
@s sockaddr int
@<Set up the listening socket@>=
int listenfd = ::socket(PF_INET,SOCK_STREAM,0);
if(listenfd < 0){
	userlog << "Could not create a socket" << std::endl;
	::_exit(1);
}@+else {
	int optval=1;
	::setsockopt(listenfd,SOL_SOCKET,SO_REUSEADDR,&optval,sizeof(optval));
}
@ @<Set up the listening socket@>=
if(listenfd >= 0) {
	struct sockaddr_in sin;
	sin.sin_addr.s_addr = INADDR_ANY;
	sin.sin_family = AF_INET;
	sin.sin_port = htons(std::atoi(configuration["listen_port"].c_str()));
	if(::bind(listenfd,(struct sockaddr*)&sin,sizeof(struct sockaddr_in))){
		userlog << "Could not bind the socket" << std::endl;
		::_exit(1);
	}
}
@ @<Check the config...@>=
check_config("listen_port",configuration,"Need a port to listen to");
@ @<Set up the listening socket@>=
if(::listen(listenfd,5)){
	userlog << "Could not listen on a socket" << std::endl;
	::_exit(1);
}
@ @<Clean up...@>=
::shutdown(listenfd,SHUT_RDWR);
::close(listenfd);
@ @<Set up the listening socket@>=
int buildfd = ::socket(PF_INET,SOCK_STREAM,0);
if(buildfd < 0){
	userlog << "Could not create a socket" << std::endl;
	::_exit(1);
}@+else {
	int optval=1;
	::setsockopt(buildfd,SOL_SOCKET,SO_REUSEADDR,&optval,sizeof(optval));
}
@ @<Set up the listening socket@>=
if(buildfd >= 0) {
	struct sockaddr_in sin;
	sin.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
	sin.sin_family = AF_INET;
	sin.sin_port = htons(std::atoi(configuration["listen_build_port"].c_str()));
	if(bind(buildfd,(struct sockaddr*)&sin,sizeof(struct sockaddr_in))){
		userlog << "Could not bind the build socket" << std::endl;
		::_exit(1);
	}
}
@ @<Check the config...@>=
check_config("listen_build_port",configuration,"Need a port to listen to");
@ @<Set up the listening socket@>=
if(::listen(buildfd,5)){
	userlog << "Could not listen on the build socket" << std::endl;
	::_exit(1);
}
@ @<Clean up...@>=
::shutdown(buildfd,SHUT_RDWR);
::close(buildfd);
@ @<Check the configuration@>=
check_config("rss-reader-path",configuration,"Need path to reader");
@ @<Variable declarations for |main|@>=
const char* rss_reader_argv[] = { "rss-reader", "-c", 0, 0 };
@ @<Check in with gittrac@>=
rss_reader_argv[2] = const_cast<char*>(configuration["rss-config"].c_str());
std::vector<const char*> rssv;
for(const char** rpp = &rss_reader_argv[0]; *rpp; ++rpp)
	rssv.push_back(*rpp);
Process process(configuration["rss-reader-path"].c_str(),rssv);
for(;;) {
	if(process.finished()) break;
	auto message = process.next();
	if(!message.empty()) messages.push_front(irc_id(message));
}
@ @<Header inclusions for |main|@>=
#include <string>
#include <cstring>
#include <cstdlib>
#include <sstream>
#include <termios.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <sys/resource.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <map>
#include <set>
#include <sys/select.h>
#include <algorithm>
#include <cctype>
#include "gitirc-check_config.h"
#include "gitirc-irc_ctx.h"
#include "gitirc-irc_id.h"
#include "gitirc-read_configuration.h"
#include <libircclient.h>
#include "json.h"
#include "gitirc-git_db.h"
#include "gitircConfig.h"
#include "gitirc-logger.h"
#include "gitirc-Process.h"
#include "gitirc-whitelist.h"
@*The JSON interface. Github sends out notifications over HTTP protocol in
JSON. We want to handle that.
@<Initialize the program@>=
bool has_httpd = false;
int http_port = -1;
if(configuration.find("http_port") != configuration.end())
	if(!configuration["http_port"].empty()) {
		http_port = std::atoi(configuration["http_port"].c_str());
		has_httpd = true;
	}
@ @<Initialize the program@>=
int http_socket = -1;
if(has_httpd) {
	if((http_socket = ::socket(AF_INET,SOCK_STREAM,0)) < 0) {
		userlog << "Could not create http socket" << std::endl;
		has_httpd = false;
		http_port = -1;
	}@+else {
		int optval=1;
		::setsockopt(http_socket,SOL_SOCKET,SO_REUSEADDR,&optval,sizeof(optval));
	}
}
@ @<Initialize the program@>=
if(has_httpd) {
	struct sockaddr_in sin;
	sin.sin_addr.s_addr = INADDR_ANY;
	sin.sin_family = AF_INET;
	sin.sin_port = htons(http_port);
	if(::bind(http_socket,(struct sockaddr*)&sin,sizeof(struct sockaddr_in))){
		userlog << "Could not bind the http socket" << std::endl;
		has_httpd = false;
		http_port = -1;
		::close(http_socket);
	}
}
@ @<Initialize the program@>=
if(has_httpd && ::listen(http_socket,5)) {
	userlog << "Could not listen on the http socket" << std::endl;
	has_httpd = false;
	http_port = -1;
	::close(http_socket);
}
int httpfd = gitirc_constants::invalid_fd;
bool http_msg_complete = false;
@ @<Initialize the program@>=
std::shared_ptr<char> httpbuf;
if(has_httpd) httpbuf = std::shared_ptr<char>(new char[1<<18],std::default_delete<char[]>());
std::string http_message;
if(has_httpd && !httpbuf) {
	userlog << "Uh oh, we do not have much memory. Bail" << std::endl;
	::_exit(1);
}
@ @<Clean up after ourselves@>=
if(has_httpd) {
	::shutdown(http_socket,SHUT_RDWR);
	::close(http_socket);
	if(httpfd>=0) {
		::shutdown(httpfd,SHUT_RDWR);
		::close(httpfd);
		httpfd = gitirc_constants::invalid_fd;
	}
}
@ @<Check |http_socket| for messages@>=
if(has_httpd && ((httpfd >= 0 && FD_ISSET(httpfd,&rfds)) ||
		FD_ISSET(http_socket,&rfds))){
	if(httpfd < 0 && FD_ISSET(http_socket,&rfds)) {
// Probably should check IP address of client here
		struct sockaddr_in remote;
		socklen_t remote_len = sizeof(remote);
		httpfd = ::accept(http_socket,(struct sockaddr*)&remote,&remote_len);
		if(!http_whitelist.accept(remote.sin_addr)) {
			userlog << "Rejecting connection from " << inet_ntoa(remote.sin_addr) << std::endl;
			::close(httpfd);
			httpfd = gitirc_constants::invalid_fd;
			http_msg_complete = false;
		} else {
			userlog << "Accepting connection from " << inet_ntoa(remote.sin_addr) << std::endl;
			http_message.clear();
			http_msg_complete = false;
		}
	}
	if(httpfd>=0 && FD_ISSET(httpfd,&rfds)){
		int numread;
		if((numread = ::read(httpfd,httpbuf.get(),1<<18)) <= 0) {
			userlog << "Received " << numread << " bytes from remote host on http port" << std::endl;
			::close(httpfd);
			httpfd = gitirc_constants::invalid_fd;
			http_msg_complete = (numread == 0);
		}@+else if(numread > 0) { 
			userlog << "Received " << numread << " bytes from remote host on http port" << std::endl;
			http_message.append(httpbuf.get(),numread);
			@<Find the content length header@>@;
			@<If we have it all, return a reply, close the connection@>@;
		}
	}
}
@ @<Configure the whitelist@>=
if(configuration.find("whitelist") != configuration.end()) {
	auto s=configuration["whitelist"];
	auto p = std::find_if(s.begin(),s.end(),std::not1(spaceFinder()));
	while(p != s.end()) {
		auto q = std::find_if(p,s.end(),spaceFinder());
		http_whitelist.insert(std::string(p,q));
		p = std::find_if(q,s.end(),std::not1(spaceFinder()));
	}	
}
@ @<Find the content length header@>=
http_message.erase(std::remove(http_message.begin(),http_message.end(),'\r'),http_message.end());
auto cloff = http_message.find("Content-Length:");
if(cloff == std::string::npos)
	cloff = http_message.find("content-length:");
unsigned int content_length = 0;
if(cloff != std::string::npos) {
	auto cli = std::find(http_message.begin() + cloff,http_message.end(),':');
	if(cli != http_message.end()) ++cli;
	if(cli != http_message.end()) ++cli;
	for(;cli != http_message.end() && *cli != '\r' && *cli != '\n';++cli) {
		if(std::isdigit(*cli)) {
			content_length *= 10;
			content_length += *cli - '0';
		}
	}
}
@ @<If we have it all, return a reply, close the connection@>=
cloff = http_message.find("\n\n");
if(cloff != std::string::npos) {
	cloff += 2;
	if(http_message.size() >= cloff+content_length) {
		http_msg_complete = true;
		auto prot = http_message.begin();
		for(auto ii = 0;ii<2; ++ii) {
			prot = std::find(prot,http_message.end(),' ');
			++prot;
		}
		std::stringstream ss;
		ss << std::string(prot,std::find(prot,http_message.end(),'\n'))
			<< " 200 OK\r\nConnection: close\r\n\r\n";
		userlog << "Sending reply " << ss.str() << std::endl;
		::write(httpfd,ss.str().data(),ss.str().size());
		::close(httpfd);
		::shutdown(httpfd,SHUT_RDWR);
		httpfd = gitirc_constants::invalid_fd;
	}
}
@ @<Check |http_socket| for messages@>=
if(http_msg_complete) {
	http_message.erase(std::remove(http_message.begin(),http_message.end(),'\r'),http_message.end());
	userlog.get_stream() << http_message << std::endl;
}
@ @<Function declarations for |main|@>=
int hex2int(char ch);
@ @c namespace {
int hex2int(char ch)
{
	int ret = 0;
	switch(ch) {
		case '0': case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			ret = ch - '0';
			break;
		case 'A': case 'B': case 'C':
		case 'D': case 'E': case 'F':
			ret = 10 + ch - 'A';
			break;
		case 'a': case 'b': case 'c':
		case 'd': case 'e': case 'f':
			ret = 10 + ch - 'a';
			break;
		default:
			break;
	}
	return ret;
}}
@ @<Function declarations for |main|@>=
std::string urldecode(const std::string& s);
@ @c
namespace {
std::string urldecode(const std::string& s)
{
	int state = 0;
	int ch = 0;
	std::string ret;
	ret.reserve(s.size());
	for(auto p = s.begin(); p != s.end(); ++p) {
		switch(state) {
		case 0: @<Check for \.{\char`\%} character@>@;@+break;
		case 1: ch = hex2int(*p);
			state = 2;
			break;
		case 2: {
				ch <<= 4;
				ch |= hex2int(*p);
				char c = static_cast<char>(ch & 0xff);
				ret.append(1,c);
				state = 0;
			}
			break;
		default: break;
		}
	}
	return ret;
}}
@ @<Check for \.{\char`\%} character@>=
if(*p == '%') state = 1;
else ret.append(1,*p);
@ First phase is to find the payload and decode it.
@<Process http message@>=
if(http_message.empty()) {
	userlog << "No data in http message; dropping it." << std::endl;
	http_msg_complete = false;
	goto done_processing_http;
}
@ @<Process http message@>=
size_t offset;
std::string github_event;
if((offset = http_message.find("\n\n")) == std::string::npos)
	@<Does not look like an http message, as there is not header separator@>@;
else @<Get the JSON event from the body@>@;
@ After this finishes, |http_message| will be a JSON string to parse.
@<Get the JSON event from the body@>={
	@<Get the event that we have received@>@;
	auto pp = http_message.begin() + offset + 2;
	if(http_message.find("Content-Type: application/json") == std::string::npos
			&& http_message.find("content-type: application/json") == std::string::npos)
		@<Not JSON, so we believe it is urlencoded@>@;
	else {
		userlog << "Looks like it is JSON" << std::endl;
		http_message = std::string(pp,http_message.end());
	}
}
@ @<Does not look like an http message, as there is not header separator@>={
	userlog << "Did not find header terminator!" << std::endl;
	http_msg_complete = false;
	http_message.clear();
	goto done_processing_http;
}
@ @<Get the event that we have received@>=
size_t event_offset = http_message.find("X-Github-Event:");
if(event_offset == std::string::npos)
	event_offset = http_message.find("X-GitHub-Event:");
if(event_offset != std::string::npos) {
	auto eob = http_message.begin() + event_offset;
	eob = std::find(eob,http_message.end(),':')+2;
	github_event.assign(eob,std::find(eob,http_message.end(),'\n'));
}@+else {
	userlog << "Did not find Github-Event header!" << std::endl;
	http_msg_complete = false;
	http_message.clear();
	goto done_processing_http;
}
@ We need to decode the body into JSON.
@<Not JSON, so we believe it is urlencoded@>={
	userlog << "I am assuming message is urlencoded!" << std::endl;
	pp = std::find(pp,http_message.end(),'=');
	if(pp != http_message.end()) http_message =
		urldecode(std::string(++pp,http_message.end()));
	else @<Message is supposed to start with \.{payload=}@>@;
}
@ @<Message is supposed to start with \.{payload=}@>={
	userlog << "Did not find = in urlencoded payload!\n" << std::endl;
	http_msg_complete = false;
	http_message.clear();
	goto done_processing_http;
}
@ Second phase is to parse it.
@s json_node int
@<Process http message@>=
std::string::const_iterator peqc;
std::shared_ptr<@[JSON::json_node@]> payp = JSON::json_node::parse(http_message.begin(),
	http_message.end(),&peqc);
if(!payp) {
	userlog << "Failed to parse body!\n" << std::endl;
	http_msg_complete = false;
	http_message.clear();
	goto done_processing_http;
}@+else {
#if 0
	userlog.get_stream() << gitirc_logger::get_time();
	payp->print(userlog,gitirc_logger::get_time());
	userlog.get_stream() << std::endl;
#endif
}
@ We should have a parsed JSON message from github.  Now we walk through the
commits to check if there is anything we have not seen yet.
@<Process http message@>=
if(github_event == "fork")
	@<Report that the repository has been forked@>@;
else if(github_event == "pull_request")
	@<Report on a pull request@>@;
else if(github_event == "push")
	@<Report on a push@>@;
else if(github_event == "issue_comment")
	@<Report on an issue@>@;
else if(github_event == "watch")
	@<Report on a watcher@>@;
else if(github_event == "commit_comment")
	@<Report on a commit comment@>@;
else {
	userlog << "Unknown message type received" << std::endl;
	std::stringstream to_gitirc;
	to_gitirc << "Received a \"" << github_event << "\" from github, but I don't"
		" know how to handle it" << std::endl;
	messages.push_back(irc_id(to_gitirc.str()));
}
@ We are not going to do this, but if we did, here is what we would do.
@<Report on a commit comment@>={
#if 0
	const std::string& commenter = (*payp)["comment"]["user"]["login"].get();
	std::string commit = the_repo.short_sha1((*payp)["comment"]
		["commit_id"].get().substr(0,7));
	if(commit.empty()) commit = (*payp)["comment"]["commit_id"].get();
	std::stringstream to_gitirc;
	to_gitirc << commenter << " commented on https://github.com/htcondor/"
		"htcondor/commit/" << commit;
	messages.push_back(irc_id(to_gitirc.str()));
#endif
}
@ @<Report on an issue@>={
	const std::string& action = (*payp)["action"].get();
	const std::string& url = (*payp)["issue"]["html_url"].get();
	const std::string& owner = (*payp)["sender"]["login"].get();
	if(!owner.empty() && !url.empty() && !action.empty()) {
		std::stringstream to_gitirc;
		to_gitirc << owner << " has " << action << " an issue at " << url;
		messages.push_back(irc_id(to_gitirc.str()));
	}
}
@ @<Report on a push@>=
need_to_read_repo = true;
@ @<Report that the repository has been forked@>={
	const std::string& owner = (*payp)["forkee"]["owner"]["login"].get();
	const std::string& forked_url = (*payp)["forkee"]["html_url"].get();
	const std::string& our_repo = (*payp)["repository"]["full_name"].get();
	if(!owner.empty() && !forked_url.empty() && !our_repo.empty()) {
		std::stringstream to_gitirc;
		to_gitirc << owner << " has forked " << our_repo << " at " << forked_url;
		messages.push_back(irc_id(to_gitirc.str()));
	}
}
@ @<Report on a pull request@>={
	const std::string& action = (*payp)["action"].get();
	const std::string& url = (*payp)["pull_request"]["_links"]["html"]["href"].get();
	const std::string& username = (*payp)["sender"]["login"].get();
	if(!action.empty() && !url.empty() && !username.empty()) {
		std::stringstream to_gitirc;
		to_gitirc << username << " has " << action << " a pull request at "  << url;
		messages.push_back(irc_id(to_gitirc.str()));
	}
}
@ @<Report on a watcher@>={
	const std::string& who = (*payp)["sender"]["login"].get();
	const std::string& action = (*payp)["action"].get();
	const std::string& repo = (*payp)["repository"]["full_name"].get();
	std::stringstream to_gitirc;
	to_gitirc << who << " " << action << " to watch " << repo;
	messages.push_back(irc_id(to_gitirc.str()));
}
