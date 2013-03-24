@s std int
@s string int
@ @(gitirc-get_line_from_pipe.h@>=
#ifndef GITIRC_GET_LINE_FROM_PIPE_H
#define GITIRC_GET_LINE_FROM_PIPE_H
#include <string>
int get_line_from_pipe(std::string&s, int fd);
#endif // |GITIRC_GET_LINE_FROM_PIPE_H|
@ @c
#include "gitirc-get_line_from_pipe.h"
#include <unistd.h>
#include <string>
int get_line_from_pipe(std::string&s, int fd)
{
	s.clear();
	char ch;
	int i = 0;
	while(::read(fd,&ch,1)>0){
		if(ch == '\n')
			break;
		++i;
		s += ch;
	}
	return i;
}
