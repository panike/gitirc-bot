@
@s pid_t int
@s std int
@s string int
@(gitirc-Process.h@>=
#ifndef GITIRC_PROCESS_H
#define GITIRC_PROCESS_H
#include <sys/types.h>
#include <string>
#include <vector>
@ @(gitirc-Process.h@>=
class Pipe {
public:
	std::string getline();
	Pipe(int fdi = -1) : fd(fdi) { it = s.begin(); };
	void close();
	~Pipe();
	Pipe(const Pipe&) = delete;
	Pipe(Pipe&& p);
	Pipe& operator=(const Pipe&) = delete;
	Pipe& operator=(Pipe&&);
	bool eof() { return s.empty() && fd < 0; }
private:
	std::string s;
	std::string::iterator it;
	int fd;
};
@ @(gitirc-Process.h@>=
class Process {
public:
	Process(const char* exe,std::vector<const char*>& argv);
	std::string next();
	void close();
	~Process();
	int check_status();
	bool finished() { return ppipe.eof(); }
	static char* const* envp;
private:
	Process();
	Process& operator=(const Process& gp);
	Pipe ppipe;
	pid_t pid;
	int status;
	bool waited;
};
@ @(gitirc-Process.h@>=
#endif // |GITIRC_PROCESS_H|
@ @c
#include "gitirc-Process.h"
#include <unistd.h>
#include <sys/wait.h>
#include "gitirc-logger.h"
@<Declare |Process| variables@>@;
int Process::check_status()
{
		if(!waited) {
			waitpid(pid,&status,0);
			waited=true;
		}
		return status;
}
@ @<Declare |Process| variables@>=
char* const* Process::envp;
@ @c
extern gitirc_logger userlog;
Process::Process(const char* path, std::vector<const char*>& argv) : status(-1),
	waited(false)
{
	if(argv.empty() || argv.back() != 0) argv.push_back(0);
	int lfd[2];
	pipe(lfd);
	if((pid = fork()) > 0)
		::close(lfd[1]);
	else {
		::close(lfd[0]);
		::close(1);
		dup2(lfd[1],1);
		if(execve(path,static_cast<char*const*>(const_cast<char**>(&argv[0])),envp))
			::_exit(1);
	}
	userlog << "Running the command \"" << path << "\",";
	for(const char** pp = &argv[0]; *pp; ++pp)
		userlog.get_stream() << " \"" << *pp << "\"";
	userlog.get_stream() << std::endl;
	userlog.flush();
	ppipe = std::move(Pipe(lfd[0]));
}
@ @c
Process::~Process()
{
	if(!waited)
		wait(0);
}
@ @c
std::string Process::next()
{
	return ppipe.getline();
}
@ @c
void Process::close()
{
	ppipe.close();
}
@ @c
std::string Pipe::getline()
{
	std::string ret;
	char buf[512];
	for(;;) {
		if(fd < 0 && s.empty()) return std::string();
		while(it != s.end() && *it == '\n') ++it;
		if(it != s.end()) {
			auto p = it;
			while(p != s.end() && *p != '\n') ++p;
			if(p != s.end() && *p == '\n') {
				ret.assign(it,p);
				it = p+1;
				return ret;
			}
			if(p == s.end() && fd < 0) {
				ret.assign(it,p);
				s.clear();
				it = s.begin();
				return ret;
			}
		} else {
			s.clear();
			it = s.begin();
		}
		if(fd < 0 && s.empty()) return std::string();
		int numread = ::read(fd,buf,512);
		if(numread <= 0) close();
		else {
			s.erase(s.begin(),it);
			s.append(buf,numread);
			it = s.begin();
		}
	}
	return ret;
}
@ @c
void Pipe::close()
{
	if(fd >= 0) ::close(fd);
	fd = -1;	
}
@ @c
Pipe::~Pipe()
{
	close();
}
@ @c
Pipe::Pipe(Pipe&& p) : s(std::move(p.s)), fd(p.fd)
{
	p.fd = -1;
}
@ @c
Pipe& Pipe::operator=(Pipe&& p)
{
	if(this == &p) return *this;
	fd = p.fd;
	s = std::move(p.s);
	p.fd = -1;
	return *this;
}
