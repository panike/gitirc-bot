@
@s git_process int
@s Process int
@s std int
@s string int
@(gitirc-git_process.h@>=
#ifndef GITIRC_GIT_PROCESS_H
#define GITIRC_GIT_PROCESS_H
#include "gitirc-Process.h"
#include <string>
class git_process : public Process {
public:
	git_process(std::vector<const char*>& argv);
	~git_process()@+{}
	static std::string gitrepo;
	static std::string gitpath;
private:
	git_process();
	git_process& operator=(const git_process& gp);
};
#endif // |GITIRC_GIT_PROCESS_H|
@ @<Variables for |git_process|@>=
std::string git_process::gitrepo;
std::string git_process::gitpath;
@ @c
#include "gitirc-git_process.h"
@<Variables for |git_process|@>@;
git_process::git_process(std::vector<const char*>& argv) :
	Process(gitpath.c_str(),argv) {}
