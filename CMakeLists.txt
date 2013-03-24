# A CMake file for gitirc-bot

cmake_minimum_required(VERSION 2.8)

project(gitirc)

set (CMAKE_SKIP_BUILD_RPATH 1)
set (gitirc_VERSION_MAJOR 0)
set (gitirc_VERSION_MINOR 1)

configure_file (
	"${PROJECT_SOURCE_DIR}/gitircConfig.sh.in"
	"${PROJECT_BINARY_DIR}/gitircConfig.sh"
)

add_definitions(-Wall -O2 -std=c++0x)

find_library (LIBIRCCLIENT libircclient
PATHS /home/nwp/libircclient-1.6/src
HINTS /afs/cs.wisc.edu/u/n/w/nwp/Downloads/libircclient-1.3/src)

add_custom_command(OUTPUT gitircConfig.h
	COMMAND	${PROJECT_BINARY_DIR}/gitircConfig.sh ${PROJECT_BINARY_DIR}/gitircConfig.h ${PROJECT_SOURCE_DIR})

if(LIBIRCCLIENT-NOTFOUND)
	message(FATAL-ERROR "libircclient not found")
endif(LIBIRCCLIENT-NOTFOUND)

include_directories("${PROJECT_BINARY_DIR}" "${PROJECT_SOURCE_DIR}/libircclient/include")

foreach(webfile gitirc-bot.w gitirc-Process.w gitirc-RSSreader.w
gitirc-check_config.w gitirc-get_line_from_pipe.w gitirc-logger.w
gitirc-get_refname.w gitirc-get_sha1.w gitirc-git_process.w gitirc-irc_ctx.w
gitirc-irc_id.w gitirc-is_interesting_ref.w gitirc-json.w gitirc-git_db.w
gitirc-read_configuration.w gitirc-wget_process.w rss-reader.w)
	string (REGEX REPLACE "[.]w$" ".cpp" _webfile ${webfile})
	add_custom_command(OUTPUT ${_webfile} COMMAND ctangle -bhp ${webfile} - ${_webfile}
		DEPENDS ${webfile})
endforeach(webfile)

foreach(webfile gitirc-bot.w gitirc-Process.w gitirc-RSSreader.w
gitirc-check_config.w gitirc-get_line_from_pipe.w gitirc-logger.w
gitirc-get_refname.w gitirc-get_sha1.w gitirc-git_process.w gitirc-irc_ctx.w
gitirc-irc_id.w gitirc-is_interesting_ref.w gitirc-json.w gitirc-git_db.w
gitirc-read_configuration.w gitirc-wget_process.w rss-reader.w)
	string (REGEX REPLACE "[.]w$" ".tex" _webfile ${webfile})
	add_custom_target(${_webfile} cweave -bhp ${webfile} - ${_webfile}
		DEPENDS ${webfile})
endforeach(webfile)

foreach(webfile gitirc-bot.tex gitirc-Process.tex gitirc-RSSreader.tex
gitirc-check_config.tex gitirc-get_line_from_pipe.tex gitirc-logger.tex
gitirc-get_refname.tex gitirc-get_sha1.tex gitirc-git_process.tex
gitirc-irc_ctx.tex gitirc-irc_id.tex gitirc-is_interesting_ref.tex
gitirc-json.tex gitirc-git_db.tex gitirc-read_configuration.tex
gitirc-wget_process.tex rss-reader.tex)
	string (REGEX REPLACE "[.]tex$" ".pdf" _webfile ${webfile})
	add_custom_target(${_webfile} pdftex ${webfile}
		DEPENDS ${webfile})
endforeach(webfile)

add_library(gitirc SHARED gitirc-Process.cpp gitirc-RSSreader.cpp
gitirc-check_config.cpp gitirc-get_line_from_pipe.cpp gitirc-logger.cpp
gitirc-get_refname.cpp gitirc-get_sha1.cpp gitirc-git_process.cpp
gitirc-irc_ctx.cpp gitirc-irc_id.cpp gitirc-is_interesting_ref.cpp
gitirc-json.cpp gitirc-git_db.cpp gitirc-read_configuration.cpp
gitirc-wget_process.cpp rss-reader.cpp)

add_executable(gitirc-bot gitirc-bot.cpp gitircConfig.h)
add_executable(rss-reader rss-reader.cpp)

target_link_libraries(gitirc-bot gitirc ${PROJECT_SOURCE_DIR}/libircclient/src/libircclient.a)

target_link_libraries(rss-reader gitirc)
