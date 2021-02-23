#pragma once
#include "utils.h"
#pragma pack(push)
#pragma pack(1)

namespace fasm_info
{// fasm headers

	struct header
	{
		u32 signature;//=0x1B736166
		u8 major,minor;
		u16 length_header;//=56
		u32 offset_input_file_name;
		u32 offset_output_file_name;
		u32 offset_string_table;
		u32 length_string_table;
		u32 offset_symbol_table;
		u32 length_symbol_table;
		u32 offset_preprocessed_source;
		u32 length_preprocessed_source;
		u32 offset_assembly_dump;
		u32 length_assembly_dump;
		u32 offset_section_table;
		u32 length_section_table;
	};
	struct symbol
	{
		u64 value;
		u16 flags;
		u8 size_data;
		u8 type;
		u32 ext_sib;
		u16 pass_num_def;
		u16 pass_num_use;
		union
		{
			u32 section;
			u32 ext_symb_string_offset;
		};
		union
		{
			u32 symb_name_prep_offset;
			u32 symb_name_string_offset;
		};
		u32 line_prep_offset;
	};
	struct preprocessed_line
	{
		u32 offset_file_name;
		u32 number_line;
		union
		{
			u32 position_file;
			u32 offset_prep_line;
		};
		u32 offset_prep_line_in_macro_def;
	};
	struct row_dump
	{
		u32 offset_output;
		u32 offset_prep_line;
		u64 address;
		u32 ext_sib;
		union
		{
			u32 section;
			u32 ext_symb_string_offset;
		};
		u8 type_address;
		u8 type_code;// 16,32,64
		u8 virtual_bits;
		u8 reserved;
	};

	struct symbol_t
	{//symbol faspart;
		std::string name;
		u32 section;
		bool usable;
		u64 value;
	};
	struct line_m_t
	{//	preprocessed_line faspart;
		u32 offset;
		std::string source_name;
		u32 number_line;
	};
	struct row_dump_t
	{//row_dump faspart;
		u32 section;
		bool usable;
		line_m_t source_line;// data from associated core preprocessed line
		u32 offset_output;
	};

	struct file_table_item
	{
		std::string name;
		u32 offset;
		u32 offsetF4;
	};
	typedef std::vector<file_table_item> file_table_t;
	u32 add2file_table(file_table_t& ft,std::string fn);

	class object
	{
		FILE *pfin;
		std::string look_string_table(u32 off);
		std::string look_preproccessed_string(u32 off);
		std::string look_preproccessed_pascal_string(u32 off);
		line_m_t check_fas_preprocessed_line(u32 off_line);
		void convert(u32 off_line,const preprocessed_line& line,line_m_t& res);
		line_m_t find_source_fas_preprocessed_line(u32 off_line,std::vector<u32>& lastinstance);
		void make_rows();
		void make_symbols();
	public:
		object(bool v,int m,FILE *pf) : verbose(v),pfin(pf),ismacroexpanded(m) {}
		bool verbose;
		int ismacroexpanded;
		header head;
		std::vector<symbol_t> symbols;
		std::vector<row_dump_t> uniquerows;
		std::string input_file_name,output_file_name;
		file_table_t filetable;
		std::vector<u32> fileoffsets;
		std::vector<u32> fileoffsetsF4;
		void load_header();
		void load_obj();
	};
}
#pragma pack(pop)
