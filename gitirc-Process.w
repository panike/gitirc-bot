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
class Process {
public:
	Process(const char* exe,std::vector<const char*>& argv);
	std::string next();
	void close();
	~Process();
	int check_status();
	static char* const* envp;
private:
	Process();
	Process& operator=(const Process& gp);
	int fd;
	pid_t pid;
	int status;
	bool waited;
};
#endif // |GITIRC_PROCESS_H|
@ @c
#include "gitirc-Process.h"
#include "gitirc-get_line_from_pipe.h"
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
	if((pid = fork()) != 0)
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
	fd = lfd[0];
}
@ @c
Process::~Process()
{
	if(fd >= 0)
		::close(fd);
	if(!waited)
		wait(0);
}
@ @c
std::string Process::next()
{
	std::string ret;
	if(fd>=0)
		get_line_from_pipe(ret,fd);
	return ret;
}
@ @c
void Process::close()
{
	::close(fd);
	fd = -1;
}
