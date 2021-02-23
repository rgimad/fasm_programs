#pragma once

#include "fas_dispatcher.h"
#include "obj_dispatcher.h"
#pragma pack(push)
#pragma pack(1)

namespace cv8
{
	class object
	{
		void make_F3(fasm_info::object& fas);// add F3 field
		void make_F4(fasm_info::object& fas);// add F4 field

		typedef fasm_info::file_table_t::const_iterator file_it;
		void make_one_F2(u32 nsect,u32 nall,std::vector<std::pair<file_it,u32> >& npairs,
			std::vector<obj_win32::section_t>::iterator si,
			fasm_info::object& fas);

		u32 have_pairs_F2(u32 section,const obj_win32::section_t& sec,const fasm_info::file_table_item& fi,
			fasm_info::object& fas);
		u32 make_F2_per_section_header(u32 npairs,u32 nfiles,const obj_win32::section_t& sec);
		void make_F2(obj_win32::object& obj,fasm_info::object& fas);// add F2 field
		void make_F1_x1101(fasm_info::object& fas);
		void make_F1_0x1116();
		void make_F1_x1105(std::string symbol,u32 section_symbol_index);
		void make_F1_x110C(std::string symbol,u32 section_symbol_index);
		void make_F1(obj_win32::object& obj,fasm_info::object& fas);// add F1 field
	public:
		object(bool v) : verbose(v) {}
		bool verbose;
		std::vector<u8> debugSraw,debugSrel;
		void make_debugS(fasm_info::object& fas,obj_win32::object& obj);
	};
}
#pragma pack(pop)
