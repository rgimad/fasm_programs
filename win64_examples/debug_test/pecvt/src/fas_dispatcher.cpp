/*
	  Program add symbolic debug information in Microsoft-CodeView format into
	object file produced by fasm.
	Author Sergey Choomak.
	Released 15.02.2009.
	Free to use and modify.

	This part load info from fas file produced by fasm.
	In verbose mode loaded information printed on screen.
*/
#include <algorithm>
#include "fas_dispatcher.h"
#pragma pack(push)
#pragma pack(1)

namespace fasm_info
{
	// fas have 4 type of string:
	std::string object::look_string_table(u32 off)
	{// 1. From string table (0-terminating)
		return check_string_by_offset(pfin,head.offset_string_table,off);
	}
	std::string object::look_preproccessed_string(u32 off)
	{// 2. From preprocessed line table (0-terminating)
		return check_string_by_offset(pfin,head.offset_preprocessed_source,off);
	}
	std::string object::look_preproccessed_pascal_string(u32 off)
	{// 3. From preprocessed line table (pascal style)
		return check_pascal_string_by_offset(pfin,head.offset_preprocessed_source,off);
	}
	// 4. Token list from preprocessed line table (0-terminating)
	// used only for verbose
	std::string fas_load_tokenized_string(FILE *pfin); 
	u32 add2file_table(file_table_t& ft,std::string fn)
	{
		for(file_table_t::const_iterator si=ft.begin();si!=ft.end();++si)
			if(si->name==fn) return u32(si-ft.begin());
		ft.push_back(file_table_t::value_type());ft.back().name=fn;return (u32)(ft.size()-1);
	}

	line_m_t object::check_fas_preprocessed_line(u32 off_line)
	{
		preprocessed_line line;line_m_t res;
		check_data_value<preprocessed_line>(line,pfin,head.offset_preprocessed_source,off_line);
		res.offset=off_line;// offset of line in .fas file
		// determine source name
		if(line.number_line&0x80000000)
		{// macro
			res.source_name=look_preproccessed_pascal_string(line.offset_file_name);
		}
		else if(line.offset_file_name==0)
		{// main source
			res.source_name=input_file_name;
		}
		else
		{// source file
			res.source_name=look_preproccessed_string(line.offset_file_name);
			add2file_table(filetable,res.source_name);// add filename to list of used files
		}
		// number of source line
		res.number_line=line.number_line&~0x80000000;
		return res;
	}
	void object::convert(u32 off_line,const preprocessed_line& line,line_m_t& res)
	{
		res.offset=off_line;// offset of line in .fas file
		if(line.number_line&0x80000000)
		{// macro - never come there!
			res.source_name=look_preproccessed_pascal_string(line.offset_file_name);
			//add2file_table(filetable,filename);
		}
		else if(line.offset_file_name==0)
		{// main source
			res.source_name=input_file_name;
		}
		else
		{// source file
			res.source_name=look_preproccessed_string(line.offset_file_name);
			add2file_table(filetable,res.source_name);// add filename to list of used files
		}
		res.number_line=line.number_line&~0x80000000;// number of source line
	}
	line_m_t object::find_source_fas_preprocessed_line(u32 off_line,std::vector<u32>& lastinstance)
	{
		// if(ismacroexpanded==1)
		// can be 3 variants:
		//    1. This preprocessed line is original source code - return it.
		//    2. This preprocessed line is first line in macro expansion - 
		//                              find it invoked line and return it.
		//    3. This preprocessed line is not first line in macro expansion - 
		//                              find it code line in macro and return it.
		// else if(ismacroexpanded==2)
		// can be 3 variants:
		//    1. This preprocessed line is original source code - return it.
		//    2. This preprocessed line is first line in macro expansion - 
		//                              find it invoked line and return it.
		//    3. This preprocessed line is not first line in macro expansion - 
		//                              find it code line in macro and return it.
		// else
		// find core preprocessed line in source file from which this line invoked
			//debug in macro not supported.
			//So this function search line from which macro is invoked
		preprocessed_line line;line_m_t res;
		check_data_value<preprocessed_line>(line,pfin,
			head.offset_preprocessed_source,off_line);
		if(line.number_line&0x80000000)
		{// it is a macro
			switch(ismacroexpanded)
			{
			case 1:
				{// macro expanded and invoke place set as breakable
					preprocessed_line line2;
					// check macro invoke line
					check_data_value<preprocessed_line>(line2,pfin,
						head.offset_preprocessed_source,line.offset_prep_line);
					if(lastinstance.empty()||lastinstance.back()!=line.offset_prep_line)
					{// macro invoke line changed
						if(lastinstance.size()>=2&&*(lastinstance.end()-2)==line.offset_prep_line)
						{// return from macro
							lastinstance.pop_back();
						}
						else
						{// enter into macro
							lastinstance.push_back(line.offset_prep_line);
							off_line=line.offset_prep_line;
							line=line2;
						}
					}
					while(line.number_line&0x80000000)
					{// check in macro code line
						off_line=line.offset_prep_line_in_macro_def;
						check_data_value<preprocessed_line>(line,pfin,
							head.offset_preprocessed_source,off_line);
					}
				}
				break;
			case 2:
				{// macro expanded and macro invoke place skiped
					// not check macro invoke line
					while(line.number_line&0x80000000)
					{// check in macro code line
						off_line=line.offset_prep_line_in_macro_def;
						check_data_value<preprocessed_line>(line,pfin,
							head.offset_preprocessed_source,off_line);
					}
				}
				break;
			case 0:default:
				{// macro not expanded
					while(line.number_line&0x80000000)
					{// check macro invoke line
						off_line=line.offset_prep_line;
						check_data_value<preprocessed_line>(line,pfin,
							head.offset_preprocessed_source,off_line);
					}
				}
			}
		}
		else
		{
			lastinstance.clear();// reset macro invoke stack
		}
		convert(off_line,line,res);
		return res;
	}


	void object::make_symbols()
	{// load fas symbols
		size_t nsymbols=head.length_symbol_table/sizeof(symbol);
		printf("\n  Symbol table (nsymbols %d)\n",nsymbols);
		if(verbose)
			printf("  ¹   | offset |reloff |   value   | flags| sz | tp |extsib|psd|psu|sectn|oprepsrc |opline|\n");
		symbol asymbol;
		fseek(pfin,head.offset_symbol_table,SEEK_SET);
		symbols.resize(nsymbols);
		for(std::vector<symbol_t>::iterator si=symbols.begin();si!=symbols.end();++si)
		{
			u32 off=xtell(pfin);
			load_data_value<symbol>(asymbol,pfin);
			if(asymbol.symb_name_prep_offset&0x80000000)
				si->name=look_string_table(asymbol.symb_name_prep_offset^0x80000000);
			else
				si->name=look_preproccessed_pascal_string(asymbol.symb_name_prep_offset);
			// not use external and not relocatable
			si->usable=asymbol.type==2&&!(asymbol.section&0x80000000);
			si->section=asymbol.section&~0x80000000;// valid only for usable=true;
			si->value=asymbol.value;
			if(verbose)
			{
				std::string str;
				if(asymbol.symb_name_prep_offset&0x80000000)
					str=std::string("ST:")+si->name;
				else
					str=std::string("PL:")+si->name;
				printf(" %4d |  x%04x | x%04x | x%08x |x%04x |x%02x |x%02x |x%04x | %1d | %1d | %1d:%1d | %1d:x%04x |x%04x | %s\n"
					,si-symbols.begin(),off,off-head.offset_symbol_table
					//,u32((asymbol.value>>32)&0xffffffff)
					,u32(asymbol.value&0xffffffff)
					,asymbol.flags
					,asymbol.size_data
					,asymbol.type
					,asymbol.ext_sib
					,asymbol.pass_num_def
					,asymbol.pass_num_use
					,(asymbol.section&0x80000000)?1:0
					,asymbol.section&~0x80000000
					,(asymbol.symb_name_prep_offset&0x80000000)?1:0
					,asymbol.symb_name_prep_offset&~0x80000000
					,asymbol.line_prep_offset
					,str.c_str()
					);
			}
		}
	}

	void object::make_rows()
	{// load fas rows
		//	Fas have many lines for one point in output code section. This function select 
		//	LAST line from equals and use it as unique available breakpoint later.
		size_t nrows=head.length_assembly_dump/sizeof(row_dump);
		printf("\n  Row dumps (nrows %d)\n",nrows);
		if(verbose)
			printf("  ¹   | offset |reloff |ofile |oline |   $ address  |extsib| section |atyp|tcod|vbits|\n");
		row_dump row;
		fseek(pfin,head.offset_assembly_dump,SEEK_SET);
		row_dump_t last,curr;bool first=true;
		std::vector<u32> ln;// macro invoke stack
		for(size_t si=0;si!=nrows;++si)
		{
			u32 off=xtell(pfin);
			load_data_value<row_dump>(row,pfin);
			curr.section=row.section&~0x80000000;// valid only for usable=true;
			// not use virtual, external, not relocatable and zero sectioned
			curr.usable=!row.virtual_bits&&row.type_address==2&&
				!(row.section&0x80000000)&&curr.section!=0;
			curr.source_line=find_source_fas_preprocessed_line(row.offset_prep_line,ln);
			curr.offset_output=row.offset_output;//static_cast<u32>(row.address);//
			if(curr.usable)
			{// skip depended to external symbol
 				if(first)
				{// wait for first good symbol (change previous data)
					first=false;last=curr;
				}
				else
				{
					if(last.offset_output==curr.offset_output)
						last=curr;// find last equal addressed place in dump (change previous data)
					else
					{// find address changing place, keep last in unique list
						uniquerows.push_back(last);
						last=curr;
					}
				}
			}
			if(verbose)
			{
				printf(" %4d |  x%04x | x%04x |x%04x |x%04x |x%4x%08x |x%04x | %1d:x%04x |x%2x | %2d | x%02x |\n"
					,si,off,off-head.offset_assembly_dump
					,row.offset_output
					,row.offset_prep_line
					,u32((row.address>>32)&0xffffffff)
					,u32(row.address&0xffffffff)
					,row.ext_sib
					,(row.section&0x80000000)?1:0
					,row.section&~0x80000000
					,row.type_address
					,row.type_code
					,row.virtual_bits
					);
			}
		}
		if(verbose)
		{
			u32 off=xtell(pfin);u32 num;fread(&num,sizeof(u32),1,pfin);
			printf(" tail |  x%04x | x%04x |x%04x |\n",off,off-head.offset_assembly_dump,num);
		}
		if(!first) uniquerows.push_back(last);// keep last unique address
		// At least VS2005 require that rows in debug info inside each section need 
		// to be sorted by address.
		// To realize this cv8_maker require row sorting by section then by address.
		struct fun_sort
		{
			bool operator()(const row_dump_t& r1,const row_dump_t& r2) const
			{// compare algortihm for sorting
				return r1.section<r2.section||
					r1.section==r2.section&&r1.offset_output<r2.offset_output;
			}
		};
		std::sort(uniquerows.begin(),uniquerows.end(),fun_sort());// sort rows
		printf("\n  Unique row dumps (%d rows)\n",uniquerows.size());
		if(verbose)
		{
			printf("   ¹  |section| ofile | Nline |offprep| source\n");
			for(std::vector<row_dump_t>::iterator si=uniquerows.begin();si!=uniquerows.end();++si)
			{
				printf(" %4d | x%04x | x%04x | x%04x | x%04x | %s\n"
					,si-uniquerows.begin()
					,si->section
					,si->offset_output
					,si->source_line.number_line
					,si->source_line.offset
					,si->source_line.source_name.c_str()
					);
			}
		}
	}

	void object::load_header()
	{
		load_data_value<header>(head,pfin);// load fas header
		if(head.signature!=0x1B736166)
		{
			printf("incorrect fas file signature\n");throw 10;
		}
		input_file_name=look_string_table(head.offset_input_file_name);
		output_file_name=look_string_table(head.offset_output_file_name);
	}
	void object::load_obj()
	{// load and dispatch fas file
		add2file_table(filetable,input_file_name);

		if(verbose)
		{
			printf("  Fas file header\n");
			printf(" Input file: \"%s\"\n", input_file_name.c_str());
			printf("Output file: \"%s\"\n",output_file_name.c_str());
			printf("String  offset=x%04x length=x%04x\n",
				head.offset_string_table,head.length_string_table);
			printf("Symbol  offset=x%04x length=x%04x\n",
				head.offset_symbol_table,head.length_symbol_table);
			printf("Prepsrc offset=x%04x length=x%04x\n",
				head.offset_preprocessed_source,head.length_preprocessed_source);
			printf("Dump    offset=x%04x length=x%04x\n",
				head.offset_assembly_dump,head.length_assembly_dump);
			printf("Section offset=x%04x length=x%04x\n",
				head.offset_section_table,head.length_section_table);
/*			printf("  String table\n");
			u32 off=head.offset_string_table;u32 index=0;
			fseek(pfin,off,SEEK_SET);
			printf("  ¹   | offset |reloff | text\n");
			while(off<(head.offset_string_table+head.length_string_table))
			{
				std::string str=load_string_by_offset(pfin,0,off);
				printf(" %4d |  x%04x | x%04x | \"%s\"\n",index,off,off-head.offset_string_table,str.c_str());
				++index;off=ftell(pfin);
			}
*/		}


		make_symbols();// make symbols list
		make_rows();// make rows list with unique addresses

		if(verbose)
		{// preprocessed lines loaded only when needed or full read at verbose mode
			printf("\n  Preprocessed lines\n");
			printf("  ¹ | offset |reloff |ofile |  line  |inpfoff|omacro| filename   | tokens\n");
			preprocessed_line line;
			fseek(pfin,head.offset_preprocessed_source,SEEK_SET);u32 off=head.offset_preprocessed_source;u32 index=0;
			while(off<(head.offset_preprocessed_source+head.length_preprocessed_source))
			{
				load_data_value<preprocessed_line>(line,pfin);
				std::string str=fas_load_tokenized_string(pfin);
				std::string filename;
				if(line.number_line&0x80000000)
				{// macro
					filename=look_preproccessed_pascal_string(line.offset_file_name);
					filename=std::string("M:")+filename;
				}
				else if(line.offset_file_name==0)
				{// main source
					filename="main";
				}
				else
				{// source file
					filename=look_preproccessed_string(line.offset_file_name);
					filename=std::string("S:")+filename;
				}
				printf(" %2d |  x%04x | x%04x |x%04x | %1d:%4d | x%04x |x%04x | %10s | %s\n"
					,index,off,off-head.offset_preprocessed_source
					,line.offset_file_name
					,(line.number_line&0x80000000)?1:0
					,line.number_line&~0x80000000
					,line.position_file
					,line.offset_prep_line_in_macro_def
					,filename.c_str()
					,str.c_str());
				off=xtell(pfin);++index;
			}
		}
		if(verbose)
		{// load sections?
			fseek(pfin,head.offset_section_table,SEEK_SET);
			printf("\n  Section names from fas\n");
			while(!feof(pfin))
			{
				u32 num;size_t sz=fread(&num,sizeof(u32),1,pfin);if(sz<1) break;
				std::string str=check_string_by_offset(pfin,head.offset_string_table,num);
				printf("section name offset=x%04x {\"%s\"}\n",num,str.c_str());
			}
		}
	}

	// simple realization of showing fas tokenized strings
	std::string fas_load_tokenized_string(FILE *pfin)
	{
		std::string rc;char ccx[257];size_t ri=0;u32 sz22=0;
		while(!feof(pfin))
		{
			int ch=fgetc(pfin);
			if(!ch) break;
			switch(ch)
			{
			case 0x3b:
				ch=fgetc(pfin);
				ri=fread(ccx,1,ch,pfin);
				rc.push_back('[');
				rc.insert(rc.end(),ccx,ccx+ri);
				rc.push_back(']');
				break;
			case 0x1a:
				ch=fgetc(pfin);
				ri=fread(ccx,1,ch,pfin);
				rc.push_back('{');
				rc.insert(rc.end(),ccx,ccx+ri);
				rc.push_back('}');
				break;
			case 0x22:
				fread(&sz22,sizeof(u32),1,pfin);
				rc.push_back('\'');
				while(sz22)
				{
					u32 sz=(sz22>256)?256:sz22;
					ri=fread(ccx,1,sz,pfin);
					rc.insert(rc.end(),ccx,ccx+ri);
					sz22-=(u32)ri;
				}
				rc.push_back('\'');
				break;
			default:
				rc.push_back(char(ch));
			}
		}
		return rc;
	}
}
#pragma pack(pop)
