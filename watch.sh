#!/usr/bin/env bash

declare script_dir=''
script_dir=$(realpath --no-symlinks "$(dirname "${BASH_SOURCE[0]:-$0}")")
cd "${script_dir}" || exit 1

################################################################################

declare -a lua_interpreter_command=( command luajit )

declare -i terminal_width=$(( ${COLUMNS:-$(tput cols)} - 1 ))
(( terminal_width -= (terminal_width & 1) ))

################################################################################

function lua() {
	"${lua_interpreter_command[@]}" "${@}"
}

function throw() {
	local message="${1}"

	printf '\e[41;1m ERROR \e[0m %b\n' "${message}"

	exit 1
}

function require_command() {
	local command="${1}"

	if command -v "${command}" &> '/dev/null'; then
		return 0
	fi

	throw "The command '${command}' could not be found!"
}

function watch_for_changes() {
	local file_path=''
	file_path=$(inotifywait \
		--quiet \
		--event='modify' \
		--format='%w/%f' \
		--recursive \
		--include='.*\.lua' \
		'./'
	)

	realpath \
		--relative-to="${script_dir}" \
		"${file_path}"
}

function run_lua_file() {
	local file="${1}"

	lua -- "${file}"
}

# ─ │ ╭ ╮ ╰ ╯

declare print_boxed_horizontal_line=''
print_boxed_horizontal_line=$(printf '%*s' "$(( terminal_width - 2 ))" '' | sed 's| |─|g')

function print_boxed() {
	local text="${1}"

	local -i text_width="${#text}"
	local -i padding_width=$(( (terminal_width - text_width - 2) >> 1 ))

	local padding_right=''
	padding_right=$(printf '%*s' "${padding_width}" "")

	local padding_left="${padding_right}"
	if (( (text_width & 1) == 1 )); then
		padding_left+=' '
	fi

	printf '╭%s╮\n│%s%s%s│\n╰%s╯\n\n' \
		"${print_boxed_horizontal_line}" \
		"${padding_left}" "${text}" "${padding_right}" \
		"${print_boxed_horizontal_line}"
}

################################################################################

function main() {
	require_command 'inotifywait'
	require_command "${lua_interpreter_command[0]}"
	require_command 'luarocks'

	clear

	export LUA_PATH=''
	export LUA_CPATH=''

	local lua_version=''
	lua_version=$(lua -e 'do
		print(_VERSION:match("[0-9]+%.[0-9]+"))
	end')

	echo ">>> Lua version: ${lua_version}"

	eval "$(luarocks path --lua-version="${lua_version}")"

	export LUA_PATH="${script_dir}/src/?.lua;${script_dir}/src/?/init.lua;${LUA_PATH}"

	print_boxed "Watching directory \"${script_dir}\" for changes..."

	while true; do
		local file=''
		file=$(watch_for_changes)

		clear

		print_boxed "File: \"${file}\""

		run_lua_file "${file}"
	done
}

main "${@}"
