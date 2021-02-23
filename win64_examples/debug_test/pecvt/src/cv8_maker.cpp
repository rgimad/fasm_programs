/*
	  Program add symbolic debug information in Microsoft-CodeView format into
	object file produced by fasm.
	Author Sergey Choomak.
	Released 15.02.2009.
	Free to use and modify.

	This part make debug$S section with symbolic debug information.
	Algoritm based on information from yasm source (file cv8.txt).
	But field F2 making algorithm and some constants in field F1 are modified 
	(i'm look into obj file maked by ml.exe version 8.00.50727.42).
	Algorithm md5 also from yasm source (see md5.c).
*/
#include "cv8_maker.h"
#include "md5.h"
#pragma pack(push)
#pragma pack(1)

namespace cv8
{

	void object::make_F3(fasm_info::object& fas)
	{// make used list of file names 
		u32 off0=xtell(debugSraw);
		save_data_value<u32>(0xf3,debugSraw);// field 0xF3
		save_data_value<u32>(1,debugSraw);// field len
		u32 offbeg=xtell(debugSraw);// begin of field body
		save_data_value<u8>(0,debugSraw);// initial 0
		fasm_info::file_table_t::iterator si=fas.filetable.begin();
		for(;si!=fas.filetable.end();++si)
		{// for each file in fas
			si->offset=xtell(debugSraw)-offbeg;// keep file item offset
			save_data_value<std::string>(si->name,debugSraw);// copy filename
		}
		put_data_value<u32>(xtell(debugSraw)-offbeg,debugSraw.begin()+off0+sizeof(u32));// set field len
		align4(debugSraw);// align buf
	}
	void calculate_md5(const char *fname,u8 *pout)
	{// Calculate MD5 checksum of file
		yasm_md5_context context;yasm_md5_init(&context);
		// if in fas filename without path, then fopen may fail!
		FILE *f = fopen(fname, "rb");
		if (!f)
		{// no such file: fill zeroes. MSVC say warning about file modification but can do debugging if find this file
			std::fill(pout,pout+16,0);
		}
		else
		{
			u8 *buf = new u8[1024];size_t len;
			while((len=fread(buf,1,1024,f))>0)
				yasm_md5_update(&context,buf,(unsigned long)len);
			yasm_md5_final(pout, &context);
			delete[] buf;
			fclose(f);
		}
	}
	void object::make_F4(fasm_info::object& fas)
	{// make file info's list
		struct F4_item
		{
			u32 offset;
			u16 x0110;
			u8 md5[16];
			u16 pad;
		};
		F4_item item;
		item.x0110=0x0110;// number (specification required)
		item.pad=0;// 0 (specification required)
		u32 sz_data=static_cast<u32>(sizeof(F4_item)*fas.filetable.size());
		save_data_value<u32>(0xf4,debugSraw);// field 0xF4
		save_data_value<u32>(sz_data,debugSraw);// field len
		u32 offbeg=xtell(debugSraw);// begin of field body
		u32 off=0;
		fasm_info::file_table_t::iterator si=fas.filetable.begin();
		for(;si!=fas.filetable.end();++si,off+=sizeof(F4_item))
		{// for each file in fas
			si->offsetF4=off;// keep file info offset
			item.offset=si->offset;// offset of filename in F3
			calculate_md5(si->name.c_str(),item.md5);// Calculate MD5 checksum of file
			save_data_value<F4_item>(item,debugSraw);
		}
		align4(debugSraw);// align buf
	}

/*
	In yasm one field F2 maked for each <source file,section> combination (IMHO).
	In masm one field F2 maked for every section, but each field divided on 
	subfields for every source file.
*/
	u32 object::make_F2_per_section_header(u32 npairs,u32 nfiles,const obj_win32::section_t& sec)
	{// make main header for field F2
		struct cv8_line
		{
			u32 start_offset;// offset (secrel)
			u16 section_index;// section
			u16 pad;//=0
			u32 section_used_length;// used size of section (now write entire section)
			cv8_line() : start_offset(0),section_index(0),
				pad(0) {}
		};
		u32 off0=xtell(debugSraw);
		save_data_value<u32>(0xf2,debugSraw);// field 0xF2
		u32 sz_data=npairs*2*sizeof(u32)+// size of all pairs
			sizeof(cv8_line)+//  size of section header
			nfiles*3*sizeof(u32);// size of all file headers
		save_data_value<u32>(sz_data,debugSraw);// field len
		u32 off_beg=xtell(debugSraw);// begin of field body
		cv8_line head;
		head.section_used_length=sec.objpart.SizeOfRawData;// used size of section (now write entire)
		save_data_value<cv8_line>(head,debugSraw);
//		align4(debugSraw);// align buf
		// add relocations
		obj_win32::relocation_item r0,r1;
		r0.VirtualAddress=off_beg;
		r0.SymbolTableIndex=sec.symbol_index;
		r0.set_as_secrel();
		r1.VirtualAddress=off_beg+sizeof(u32);
		r1.SymbolTableIndex=sec.symbol_index;
		r1.set_as_section();
		save_data_value<obj_win32::relocation_item>(r0,debugSrel);
		save_data_value<obj_win32::relocation_item>(r1,debugSrel);
		//align4(debugSrel);// align buf
		return off0;
	}
/*
	u32 object::have_pairs_F2(u32 section,const obj_win32::section_t& sec,const fasm_info::file_table_item& fi,
		fasm_info::object& fas)
	{// calculate number of pairs
		u32 npairs=0;
		for(std::vector<fasm_info::row_dump_t>::iterator di=fas.uniquerows.begin();di!=fas.uniquerows.end();++di)
		{
			if(di->usable&&di->section==section&&di->source_line.source_name==fi.name)
				++npairs;// add this row
		}
		return npairs;
	}

	void object::make_one_F2(u32 nsect,u32 nall,std::vector<std::pair<file_it,u32> >& npairs,
		std::vector<obj_win32::section_t>::iterator si,fasm_info::object& fas)
	{
		if(nall)
		{// have lines in this section
			make_F2_per_section_header(nall,(u32)npairs.size(),*si);
			struct header
			{
				u32 filename_offset;// offsetF4 of filename
				u32 number_of_line_pairs;// pairs count
				u32 length_of_pairs;// in first: pairs len + 12
			};
			for(std::vector<std::pair<file_it,u32> >::const_iterator pi=npairs.begin();
				pi!=npairs.end();++pi)
			{// for every source file having usable lines in this section
				header head;// subfield header
				head.filename_offset=pi->first->offsetF4;// offsetF4 of filename
				head.number_of_line_pairs=pi->second;
				head.length_of_pairs=pi->second*2*sizeof(u32)+12;// len of subfield
				save_data_value<header>(head,debugSraw);
				for(std::vector<fasm_info::row_dump_t>::iterator di=fas.uniquerows.begin();di!=fas.uniquerows.end();++di)
				{// for each usable line in this section and this source file
					if(di->usable&&di->section==nsect&&di->source_line.source_name==pi->first->name)
					{// add this row
						save_data_value<u32>(
							di->offset_output-si->initPointerToRawData,debugSraw);// offset
						save_data_value<u32>(di->source_line.number_line|0x80000000,debugSraw);// line number & breakable flag
					}
				}
			}
		}
	}
*/
	void object::make_F2(obj_win32::object& obj,fasm_info::object& fas)
	{// make field F2
		u32 nsect=~0;std::string fname;
		std::vector<obj_win32::section_t>::iterator si=obj.sections.end();
		for(std::vector<fasm_info::row_dump_t>::iterator di=fas.uniquerows.begin();di!=fas.uniquerows.end();++di)
		{if(!di->usable) continue;// for each usable line
			if(di->section!=nsect)
			{// add new section
				nsect=di->section;
				if(nsect>obj.sections.size()) throw 125;// bad section
				si=obj.sections.begin()+nsect-1;
				fname.clear();// restart file name  checking
				u32 nall=0;// full count of pairs
				u32 nfiles=0;// count of used source files
				std::string fname1;
				for(std::vector<fasm_info::row_dump_t>::iterator di1=di;
					di1!=fas.uniquerows.end();++di1)
				{if(!di1->usable) continue;// not use it
					if(di1->section!=nsect)
						break;// end of this section
					if(fname1!=di1->source_line.source_name)
					{// next file
						fname1=di1->source_line.source_name;++nfiles;
					}
					++nall;
				}
				if(!nall||!nfiles) throw 131;
				make_F2_per_section_header(nall,nfiles,*si);
			}
			if(fname!=di->source_line.source_name)
			{// add new source file header
				fname=di->source_line.source_name;
				u32 np=0;// count of pairs in this file and this section
				for(std::vector<fasm_info::row_dump_t>::iterator di1=di;
					di1!=fas.uniquerows.end();++di1)
				{if(!di1->usable) continue;// not use it
					if(di1->section!=nsect||fname!=di1->source_line.source_name)
						break;// end of this section or this file
					++np;
				}
				if(!np)
					throw 129;// must be not equal zero
				file_it fi=fas.filetable.begin();
				for(;fi!=fas.filetable.end();++fi)
				{// search this file and his line count
					if(fname==fi->name)
						break;// find it
				}
				if(fi==fas.filetable.end())
					throw 129;// no file record
				struct header
				{
					u32 filename_offset;// offsetF4 of filename
					u32 number_of_line_pairs;// pairs count
					u32 length_of_pairs;// in first: pairs len + 12
				};
				header head;// subfield header
				head.filename_offset=fi->offsetF4;// offsetF4 of filename
				head.number_of_line_pairs=np;
				head.length_of_pairs=np*2*sizeof(u32)+12;// len of subfield
				save_data_value<header>(head,debugSraw);
			}
			// write lines pair for this row
			save_data_value<u32>(di->offset_output-si->initPointerToRawData,debugSraw);// offset
			save_data_value<u32>(di->source_line.number_line|0x80000000,debugSraw);// line number & breakable flag
		}
	}
/*
//			for(file_it fi=fas.filetable.begin();fi!=fas.filetable.end();++fi)
//			{// for each filename
		for(std::vector<obj_win32::section_t>::iterator si=obj.sections.begin();si!=obj.siE;++si)
		{// for each section
			if(!si->iscode())
				continue;// only executable segments
			std::vector<std::pair<file_it,u32> > npairs;u32 nall=0;
			u32 nsect=static_cast<u32>(si-obj.sections.begin()+1);
			for(file_it fi=fas.filetable.begin();fi!=fas.filetable.end();++fi)
			{// for each filename
				u32 np=have_pairs_F2(nsect,*si,*fi,fas);
				if(np)
				{
					npairs.push_back(std::pair<file_it,u32> (fi,np));
					nall+=np;
				}
	}
			make_one_F2(nsect,nall,npairs,si,fas);
//}	//npairs.clear();nall=0;}
		}
	}
*/

	void object::make_F1_x1101(fasm_info::object& fas)
	{// item 0x1101 - object file name
		struct item
		{
			u16 size;// item len
			u16 type;//=x1101 item type
			u32 signature;//=0 asm signature
			item(size_t namelen) : type(0x1101),signature(0),
				size(static_cast<u16>(sizeof(item)-sizeof(u16)+namelen)) {}
		};
		save_data_value<item>(item(fas.output_file_name.size()+1),debugSraw);// save header
		save_data_value<std::string>(fas.output_file_name,debugSraw);// save filename
	}
	void object::make_F1_0x1116()
	{// item 0x1116 - creator
		const std::string creator("fasm 1.67.29 with debug symbols");
		u32 off0=xtell(debugSraw);
		struct item
		{
			u16 size;// item len
			u16 type;//=x1116 item type
			u32 lang;//=3 masm language
			u32 target;//=6? i386?
			u32 flasgs;//=0 
			u32 version;//=0 
			item(size_t namelen) : type(0x1116),lang(3),flasgs(0),
				target(3),version(8),// from ml.exe
				//target(6),version(0),// from yasm
				size(static_cast<u16>(sizeof(item)-sizeof(u16)+namelen+sizeof(u16))) {}
		};
		save_data_value<item>(item(creator.size()+1),debugSraw);// save header
		save_data_value<std::string>(creator,debugSraw);// save creator name
		save_data_value<u16>(0,debugSraw);// no additional CL pairs
	}
	void object::make_F1_x1105(std::string symbol,u32 section_symbol_index)
	{// item 0x1105 - code label symbol
		struct item
		{
			u16 size;// item len
			u16 type;//=x1105 item type
			u32 secrel;//=0
			u16 section;//=0
			u8 flags;//=0 no flags
			item(size_t namelen) : type(0x1105),secrel(0),section(0),flags(0),
				size(static_cast<u16>(sizeof(item)-sizeof(u16)+namelen)) {}
		};
		u32 off0=xtell(debugSraw);
		save_data_value<item>(item(symbol.size()+1),debugSraw);// save header
		save_data_value<std::string>(symbol,debugSraw);// save symbol name
		// add relocations
		obj_win32::relocation_item r0,r1;
		r0.VirtualAddress=off0+2*sizeof(u16);
		r0.SymbolTableIndex=section_symbol_index;
		r0.set_as_secrel();
		r1.VirtualAddress=off0+2*sizeof(u16)+sizeof(u32);
		r1.SymbolTableIndex=section_symbol_index;
		r1.set_as_section();
		save_data_value<obj_win32::relocation_item>(r0,debugSrel);
		save_data_value<obj_win32::relocation_item>(r1,debugSrel);
	}
	void object::make_F1_x110C(std::string symbol,u32 section_symbol_index)
	{// item 0x1105 - code label symbol
		struct item
		{
			u16 size;// item len
			u16 type;//=x110C item type
			// may be:
			// 0x20 -> db
			// 0x21 -> dd
			// 0x22 -> dd
			u32 symtype;//=0x20 only now
			u32 secrel;//=0
			u16 section;//=0
			item(size_t namelen) : type(0x110c),symtype(0x20),secrel(0),section(0),
				size(static_cast<u16>(sizeof(item)-sizeof(u16)+namelen)) {}
		};
		u32 off0=xtell(debugSraw);
		save_data_value<item>(item(symbol.size()+1),debugSraw);// save header
		save_data_value<std::string>(symbol,debugSraw);// save symbol name
		// add relocations
		obj_win32::relocation_item r0,r1;
		r0.VirtualAddress=off0+2*sizeof(u16)+1*sizeof(u32);
		r0.SymbolTableIndex=section_symbol_index;
		r0.set_as_secrel();
		r1.VirtualAddress=off0+2*sizeof(u16)+2*sizeof(u32);
		r1.SymbolTableIndex=section_symbol_index;
		r1.set_as_section();
		save_data_value<obj_win32::relocation_item>(r0,debugSrel);
		save_data_value<obj_win32::relocation_item>(r1,debugSrel);
	}
	void object::make_F1(obj_win32::object& obj,fasm_info::object& fas)
	{// make field F1
		u32 off0=xtell(debugSraw);
		save_data_value<u32>(0xf1,debugSraw);// field 0xF1
		u32 off_len=xtell(debugSraw);
		save_data_value<u32>(0,debugSraw);// field len
		u32 offbeg=xtell(debugSraw);// begin of field body
		make_F1_x1101(fas);// item 0x1101 - object file name
		make_F1_0x1116();// item 0x1116 - creator name
		size_t sz0=obj.symbols.size();// number of symbols loaded from obj
		for(std::vector<fasm_info::symbol_t>::const_iterator si=fas.symbols.begin();si!=fas.symbols.end();++si)
		{
			if(!si->usable)
				continue;
			if(obj.sections.size()<=(si->section-1))
				throw 5;// error - bad section!!
			// fill obj symbol table
			// 1. search symbol in currently available
			size_t sz=0;bool have=false;
			u32 isaux=0;u32 index=0;
			for(std::vector<obj_win32::symbol_t>::iterator osi=obj.symbols.begin();sz!=sz0;++osi,++sz)
			{// search only in preloaded
				if(isaux) --isaux;// skip aux symbols
				else
				{
					isaux=osi->objpart.NumberOfAuxSymbols;// to skip next aux symbols
					if(si->name==osi->name)
					{
						index=static_cast<u32>(osi-obj.symbols.begin());
						have=true;break;
					}
				}
			}
			if(!have)
			{// 2. add new symbol in table
				index=static_cast<u32>(obj.symbols.size());
				obj.symbols.push_back(obj_win32::symbol_t());
				obj_win32::symbol_t& symbol=obj.symbols.back();
				if(obj.sections[si->section-1].iscode())
					symbol.set_as_local_code(si->name,si->section,static_cast<u32>(si->value));
				else
					symbol.set_as_local_data(si->name,si->section,static_cast<u32>(si->value));
			}

			// fill field F1
			if(obj.sections[si->section-1].iscode())
			{// code label
				make_F1_x1105(si->name,index);//obj.sections[si->section-1].symbol_index);
			}
			else
			{// data
				make_F1_x110C(si->name,index);//obj.sections[si->section-1].symbol_index);
			}
		}
		put_data_value<u32>(xtell(debugSraw)-offbeg,debugSraw.begin()+off_len);// set field len
		align4(debugSraw);// align buf
	}

	void object::make_debugS(fasm_info::object& fas,obj_win32::object& obj)
	{
		save_data_value<u32>(0x4,debugSraw);// debug signature
		make_F3(fas);// add F3 field
		make_F4(fas);// add F4 field
		make_F2(obj,fas);// add F2 field
		make_F1(obj,fas);// add F1 field
	}
}
#pragma pack(pop)
