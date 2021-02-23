/*
	  Program add symbolic debug information in Microsoft-CodeView format into
	object file produced by fasm.
	Author Sergey Choomak.
	Released 15.02.2009.
	Free to use and modify.

	This part load info from obj file produced by fasm (or other makers).
	Verbose not realized (use another programs like pedump).
	Also part save modified information into new obj file.
*/
#include <algorithm>
#include "obj_dispatcher.h"
#pragma pack(push)
#pragma pack(1)

namespace obj_win32
{

	const u32 supported_machine_id=0x14c;
/*	#define COFF_IMAGE_FILE_32BIT_MACHINE	0x0100
	#define COFF_IMAGE_FILE_BYTES_REVERSED_LO	0x0080
	#define COFF_IMAGE_FILE_LINE_NUMS_STRIPPED	0x0004
	#define COFF_IMAGE_FILE_LOCAL_SYMS_STRIPPED	0x0008
*/

	enum section_flags
	{
		ALIGN_1BYTES=0x00100000,
		ALIGN_2BYTES=0x00200000,
		ALIGN_4BYTES=0x00300000,
		ALIGN_8BYTES=0x00400000,
		ALIGN_16BYTES=0x00500000,
		ALIGN_32BYTES=0x00600000,
		ALIGN_64BYTES=0x00700000,
		ALIGN_128BYTES=0x00800000,
		ALIGN_256BYTES=0x00900000,
		ALIGN_512BYTES=0x00A00000,
		ALIGN_1024BYTES=0x00B00000,
		ALIGN_2048BYTES=0x00C00000,
		ALIGN_4096BYTES=0x00D00000,
		ALIGN_8192BYTES=0x00E00000,

		CNT_CODE=0x00000020,
		CNT_INITIALIZED_DATA=0x00000040,
		CNT_UNINITIALIZED_DATA=0x00000080,
		MEM_DISCARDABLE=0x02000000,
		MEM_EXECUTE=0x20000000,
		MEM_READ=0x40000000,
		MEM_WRITE=0x80000000,
		debug_section_glags=(ALIGN_1BYTES|CNT_INITIALIZED_DATA|MEM_DISCARDABLE|MEM_READ),

	//	LNK_NRELOC_OVFL=0x01000000,
	//	TYPE_NO_PAD=0x00000008,
	//	LNK_INFO=0x00000200,
	//	LNK_REMOVE=0x00000800,
	//	//LNK_COMDAT
	//	GPREL=0x00008000,
	//	MEM_NOT_CACHED=0x04000000,
	//	MEM_NOT_PAGED=0x08000000,
	//	MEM_SHARED=0x10000000,
	};
	enum relocation_types
	{
		//I386_DIR16=0x0001,
		I386_DIR32  =0x0006,
		I386_SECTION=0x000A,
		I386_SECREL =0x000B,
	};
	enum symbol_types
	{
		SUNDEFINED=0,
		SABSOLUTE=-1,
		SDEBUG=-2,
	};
	enum symbol_classes
	{
		SEXTERNAL=2,
		SSTATIC=3,
		SLABEL=6,
		SFUNCTION=101,
		SFILE=103,
	};

	void relocation_item::set_as_secrel()
	{
		Type=I386_SECREL;
	}
	void relocation_item::set_as_section()
	{
		Type=I386_SECTION;
	}

	bool section_t::iscode() const
	{// is section executable
		return !!(objpart.Characteristics&(CNT_CODE|MEM_EXECUTE));
	}
	void section_t::set_name(std::string s)
	{
		if(s.size()>8) s.resize(8);
		name=s;
		std::fill(objpart.Name,objpart.Name+8,'\0');
		std::copy(name.begin(),name.end(),objpart.Name);
	}
	void section_t::init(u32 flags)
	{
		objpart.VirtualSize=0;
		objpart.VirtualAddress=0;
		objpart.PointerToLinenumbers=0;
		objpart.NumberOfLinenumbers=0;
		objpart.Characteristics=flags;
			objpart.SizeOfRawData=0;
			objpart.PointerToRawData=0;
			objpart.PointerToRelocations=0;
			objpart.NumberOfRelocations=0;
	}
	void init_as_debug(section_t& s,std::string n)
	{
		s.init(debug_section_glags);
		s.set_name(n);
	}
	void section_t::save_init_pointers()
	{
		initPointerToRawData    =objpart.PointerToRawData    ;
		initPointerToRelocations=objpart.PointerToRelocations;
		initPointerToLinenumbers=objpart.PointerToLinenumbers;
	}
	void section_t::update_pointers(u32 add)
	{// move pointers after insertion of new section
		if(objpart.PointerToRawData    ) objpart.PointerToRawData    +=add;
		if(objpart.PointerToRelocations) objpart.PointerToRelocations+=add;
		if(objpart.PointerToLinenumbers) objpart.PointerToLinenumbers+=add;
	}

	void symbol_t::set_name(std::string s)
	{
		name=s;
		objpart.Name[0]='\0';objpart.Name[1]='N';
	}
	void symbol_t::set_as_local_code(std::string name,u32 section,u32 offset)
	{
		set_name(name);
		objpart.Value=offset;
		objpart.SectionNumber=section;
		objpart.Type=0;
		objpart.StorageClass=SLABEL;
		objpart.NumberOfAuxSymbols=0;
	}
	void symbol_t::set_as_local_data(std::string name,u32 section,u32 offset)
	{
		set_name(name);
		objpart.Value=offset;
		objpart.SectionNumber=section;
		objpart.Type=0;
		objpart.StorageClass=SSTATIC;
		objpart.NumberOfAuxSymbols=0;
	}

	int object::prepare_obj_header()
	{// load coff header
		load_data_value<obj_header>(head,pfin);
		if(head.Machine!=supported_machine_id)
		{
			printf("Unsupported machine type\n");return 2;
		}
		if(head.NumberOfSections==0)
		{
			printf("No sections\n");return 3;
		}
		input_unchanged_head.first=ftell(pfin);
		input_unchanged_head.second=input_unchanged_head.first+head.SizeOfOptionalHeader;
		if(head.SizeOfOptionalHeader!=0)
		{//printf("Unsupported or not object file\n");return 3;
			fseek(pfin,head.SizeOfOptionalHeader,SEEK_CUR);
		}
		initNumberOfSections=head.NumberOfSections;
		initPointerToSymbolTable=head.PointerToSymbolTable;
		initNumberOfSymbols=head.NumberOfSymbols;
		return 0;
	}

	const int NADD_DEBUG_SECTIONS=2;
	// default debug$T raw data
	const u8 def_debugT[]={0x04,0x00,0x00,0x00,0x06,0x00,0x0e,0x00,0x00,0x00,0xf2,0xf1,};
	const u32 sz_def_debugT=sizeof(def_debugT);

	void object::load_obj()
	{// load info from obj file
		// load header
		//int rc=prepare_obj_header();if(rc) throw rc;
		{// load section headers
			head.NumberOfSections+=NADD_DEBUG_SECTIONS;// additional debug sections
			sections.resize(head.NumberOfSections);
			struct op
			{
				FILE *_pf;
				op(FILE *pf) : _pf(pf) {}
				size_t operator()(section_t& sh) const 
				{
					return load_data_value<section_header>(sh.objpart,_pf);
				}
			};
			std::for_each(sections.begin(),sections.end()-NADD_DEBUG_SECTIONS,op(pfin));
		}
		input_unchanged_section_body.first=ftell(pfin);
		input_unchanged_section_body.second=head.PointerToSymbolTable;
		siE=sections.end()-NADD_DEBUG_SECTIONS;

		{// load symbols
			fseek(pfin,head.PointerToSymbolTable,SEEK_SET);
			symbols.resize(head.NumberOfSymbols);
			struct op
			{
				FILE *_pf;
				op(FILE *pf) : _pf(pf) {}
				size_t operator()(obj_win32::symbol_t& sh) const 
				{
					return load_data_value<obj_win32::symbol_table_item>(sh.objpart,_pf);
				}
			};
			std::for_each(symbols.begin(),symbols.end(),op(pfin));
		}
		initstringtableoffset=ftell(pfin);
		initstringtablelen=0;fread(&initstringtablelen,sizeof(u32),1,pfin);


		bool breakout=false;
		{// make section names, check debug sections
			for(std::vector<obj_win32::section_t>::iterator si=sections.begin();si!=siE;++si)
			{
				si->save_init_pointers();
				if(si->objpart.Name[0]=='/')
				{// in string table
					u32 soff=strtoul(make_string_8(si->objpart.Name+1).c_str(),0,0);
					si->name=check_string_by_offset(pfin,initstringtableoffset,soff);
				}
				else
				{
					si->name=make_string_8(si->objpart.Name);
				}
				if(si->name==".debug$S"||si->name==".debug$T")
				{
					breakout=true;
				}
			}
		}
		if(breakout)
		{
			printf("Already have debug info\n");throw 3;
		}

		u32 fullsectionoffset=0;
		{u32 isaux=0;for(std::vector<obj_win32::symbol_t>::iterator si=symbols.begin();si!=symbols.end();++si)
		{// make symbol names, find section symbols
			if(isaux) {--isaux;continue;}// skip aux symbols
			isaux=si->objpart.NumberOfAuxSymbols;// to skip next aux symbols
			if(!si->objpart.zeroes)
			{// in string table
				si->name=check_string_by_offset(pfin,initstringtableoffset,si->objpart.Offset);
			}
			else
			{
				si->name=make_string_8(si->objpart.Name);
			}
			for(std::vector<obj_win32::section_t>::iterator ti=sections.begin();ti!=siE;++ti)
			{// find section symbols
				if(ti->name==si->name&&(ti-sections.begin()+1)==si->objpart.SectionNumber)
				{
					if(ti->name==".text")
					{
						ti->fullsectionoffset=fullsectionoffset;
						fullsectionoffset+=ti->objpart.SizeOfRawData;
					}
					ti->symbol_index=(u32)(si-symbols.begin());// set symbol index of section
					break;
				}
			}
		}}

		u32 real_sections_end_add=NADD_DEBUG_SECTIONS*sizeof(section_header);// size to be added to section header area
		head.PointerToSymbolTable+=real_sections_end_add;// adjust begin pointer for symbol table

		// initialize debug sections
		//head.Characteristics=COFF_IMAGE_FILE_32BIT_MACHINE;
		section_t& shdS=get_debugS();init_as_debug(shdS,".debug$S");
		section_t& shdT=get_debugT();init_as_debug(shdT,".debug$T");

		// prepare debugT section for default raw data
		shdT.objpart.PointerToRelocations=0;
		shdT.objpart.NumberOfRelocations=0;
		shdT.objpart.SizeOfRawData=sz_def_debugT;
		shdT.objpart.PointerToRawData=head.PointerToSymbolTable;
		head.PointerToSymbolTable+=sz_def_debugT;// adjust begin pointer for symbol table
		{for(std::vector<obj_win32::section_t>::iterator si=sections.begin();si!=siE;++si)
		{// adjust pointers for raw data of sections
			si->update_pointers(real_sections_end_add);
		}}
	}

	void object::save_obj(FILE *pfout,
		u8 *p_raw_debugS,u32 sizeS,// debug$S section raw data
		u8 *p_rel_debugS,u32 size_relS// debug$S relocations
		)
	{// save modified obj file
		section_t& shdS=get_debugS();
		section_t& shdT=get_debugT();

		// fill pointers of debug$S section
		shdS.objpart.SizeOfRawData=sizeS;
		shdS.objpart.NumberOfRelocations=size_relS/sizeof(relocation_item);
		shdS.objpart.PointerToRawData=head.PointerToSymbolTable;
		shdS.objpart.PointerToRelocations=shdS.objpart.PointerToRawData+sizeS;
		head.PointerToSymbolTable+=(sizeS+size_relS);// adjust begin pointer for symbol table
		// adjusting pointers for raw data of sections not needed (it's a last section info)
		head.NumberOfSymbols=(u32)symbols.size();

		// make output file
		save_data_value<obj_header>(head,pfout);// save header
		if(input_unchanged_head.second!=input_unchanged_head.first)// copy original optional header (must be 0 for win32 obj!)
			copy_raw_data(pfin,pfout,input_unchanged_head.first,input_unchanged_head.second-input_unchanged_head.first);
		{// save section headers
			struct op
			{
				FILE *_pf;
				op(FILE *pf) : _pf(pf) {}
				size_t operator()(const obj_win32::section_t& sh) const 
				{
					return save_data_value<obj_win32::section_header>(sh.objpart,_pf);
				}
			};
			std::for_each(sections.begin(),sections.end(),op(pfout));
		}
		if(input_unchanged_section_body.second!=input_unchanged_section_body.first)// copy all raw&rel data of original sections
			copy_raw_data(pfin,pfout,input_unchanged_section_body.first,input_unchanged_section_body.second-input_unchanged_section_body.first);
		fwrite(def_debugT,1,sz_def_debugT,pfout);// save debug$T section default raw data
		if(p_raw_debugS) fwrite(p_raw_debugS,1,sizeS,pfout);// save debug$S section raw data
		if(p_rel_debugS) fwrite(p_rel_debugS,1,size_relS,pfout);// save debug$S section relations

		std::vector<char> addstrtable;
		{// save symbol table
			u32 isaux=0;
			for(std::vector<symbol_t>::iterator si=symbols.begin();si!=symbols.end();++si)
			{
				if(isaux) --isaux;// skip aux symbols
				else
				{
					isaux=si->objpart.NumberOfAuxSymbols;// to skip next aux symbols
					if(si->objpart.Name[0]=='\0'&&si->objpart.Name[1]=='N')
					{// make name part if needed
						if(si->name.size()<=8)
						{// simple copy text
							std::copy(si->name.begin(),si->name.end(),si->objpart.Name);
							std::fill(si->objpart.Name+si->name.size(),si->objpart.Name+8,'\0');
						}
						else
						{// make string table item
							const char *ps=si->name.c_str();
							u32 offstr=static_cast<u32>(addstrtable.size());
							addstrtable.resize(offstr+si->name.size()+1);
							std::copy(ps,ps+si->name.size()+1,addstrtable.begin()+offstr);
							si->objpart.zeroes=0;
							si->objpart.Offset=offstr+initstringtablelen;
						}
					}
				}
				save_data_value<symbol_table_item>(si->objpart,pfout);
			}
		}
		// save string table
		u32 strlen=initstringtablelen+addstrtable.size();
		save_data_value<u32>(strlen,pfout);
		copy_raw_data(pfin,pfout,initstringtableoffset+sizeof(u32),
			initstringtablelen-sizeof(u32));// copy old string table
		if(strlen!=initstringtablelen)
			fwrite(&*addstrtable.begin(),1,addstrtable.size(),pfout);// save added string table
	}
}
#pragma pack(pop)
