/*
	  Program add symbolic debug information in Microsoft-CodeView format into
	object file produced by fasm.
	Author Sergey Choomak.
	Released 15.02.2009.
	Free to use and modify.
*/
#include "fas_dispatcher.h"
#include "obj_dispatcher.h"
#include "cv8_maker.h"

//extern "C" void xtart10();
int main(int argc, char* argv[])
{
//	xtart10();
	bool rename_input=false;
	int retv=0;FILE *pfin=0;FILE *pfout=0;FILE *pffas=0;
	std::string sin,sout;
	try
	{
		const char *pin=0;
		const char *pout=0;
		bool verbose=false,skiptime=false;
		int ismacroexpanded=0;
		const char pusage[]="usage: pecvt [-h] [-v] [-t] [-m] inputFASfile outputobjfile \n";
		for(int ia=1;ia!=argc;++ia)
		{
			if(*argv[ia]=='-'||*argv[ia]=='/')
			{
				switch(tolower(argv[ia][1]))
				{
				case 'v':
					verbose=true;break;
				case 'm':
					switch(tolower(argv[ia][2]))
					{
					case 0:
						ismacroexpanded=0;break;
					case 2:
						ismacroexpanded=2;break;
					default:
						ismacroexpanded=1;break;
					}
					break;
				case 't':
					skiptime=true;break;
				case 'h':
				default:
					printf(pusage);throw 0;
				}
			}
			else
			{
				if(pin)
				{
					pout=argv[ia];
				} else if(pout)
				{
					printf("too many input files\n");throw -8;
				}else
					pin=argv[ia];
			}
		}
		if(!pin)
		{
			printf("no input file\n");printf(pusage);throw -2;
		}

		if(!(pffas=fopen(pin,"rb")))
		{
			printf("error open fas file\n");throw -3;
		}
		fasm_info::object fas(verbose,ismacroexpanded,pffas);// fas file dispatcher
		fas.load_header();

		sin=fas.output_file_name;// input obj file
		char *pbin,*pbout;
		if(!(pbin=_fullpath(0,sin.c_str(),2047)))
			{printf("can not define path to input obj file");throw -9;}
		if(!(pbout=_fullpath(0,pout,2047)))
			{free(pbin);printf("can not define path to output obj file");throw -9;}
		if(!_stricmp(pbin,pbout))
		{// input obj == output obj
			rename_input=true;sout=pout;sout+=".o";
		}
		else
			sout=pout;
		free(pbin);free(pbout);

		if(!(pfin=fopen(sin.c_str(),"rb")))
		{
			printf("error open input file\n");throw -2;
		}

		obj_win32::object obj(verbose,pfin);// coff dispatcher
		int rc=obj.prepare_obj_header();if(rc) throw rc;

		bool no_changes=false;
		if(!skiptime&&!rename_input)
		{// check change time
			if((pfout=fopen(sout.c_str(),"rb")))
			{// have result obj
				obj_win32::object objo(verbose,pfout);// coff dispatcher
				{int rc=objo.prepare_obj_header();if(rc) throw rc;}
				no_changes=(objo.head.TimeDateStamp==obj.head.TimeDateStamp);
				fclose(pfout);pfout=0;
			}
		}

		if(no_changes)
		{
			printf("no changes in input files after old output file maked\n");
		}
		else
		{
			fas.load_obj();// load fas file
			obj.load_obj();// load object file
			cv8::object cv(verbose);// codeview maker
			cv.make_debugS(fas,obj);// make codeview debug section

			// save new object file
			if(!(pfout=fopen(sout.c_str(),"w+b")))
			{
				printf("error open output file\n");throw -10;
			}
			obj.save_obj(pfout,
				cv.debugSraw.empty()?0:&*cv.debugSraw.begin(),xtell(cv.debugSraw),
				cv.debugSrel.empty()?0:&*cv.debugSrel.begin(),xtell(cv.debugSrel));
		}
	}
	catch(int n)
	{
		retv=n;rename_input=false;
	}
	if(pfin) fclose(pfin);if(pfout) fclose(pfout);if(pffas) fclose(pffas);
	if(rename_input)
	{// if input file have ".obj" extension - rename it
		rename(sin.c_str(),(sin+".old").c_str());
		rename(sout.c_str(),sin.c_str());
	}
	return retv;
}

