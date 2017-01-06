%{

#include <errno.h>
	static void s_init(void) ;
	static void s_extend(unsigned long by);
	static void s_add(const char *fmt, ...);
	static void s_dump(FILE *o);
	static int closed = 0;
	static int yyerror(char *msg,...) ;

#define PATH_MAX 4096
#define MAX_INCLUDE_DEPTH 10
	YY_BUFFER_STATE include_stack[MAX_INCLUDE_DEPTH];
	int 		include_lines[MAX_INCLUDE_DEPTH];
	char 		include_files[PATH_MAX][MAX_INCLUDE_DEPTH];
	static int include_stack_ptr = 0;
	static int adjacent_include_file  = 0;
	char curfile[PATH_MAX];

%}

include	 "<%include"
binclude "<%binclude"
comstart "<%#"
comend "%>"
cstart 	"<%C"
cend	"%>"
ws	[ \t]
nl	[\n\r]
name	[^~\"\'\`^%> \t:;\]\[<=]
AS	(as|AS|aS|As)

%x C IGNORE BINCL INCL INCLEND BINCLEND
%option noyywrap yylineno

%%
{include}	{ s_extend(10); BEGIN(INCL);	}
{comstart}	{ BEGIN(IGNORE); }
{cstart} 	{ s_extend(10); s_add("%s", "\");\n\n"); BEGIN(C);  }
\n	 	{ s_extend(5); s_add("%s", "\\n\"\n\""); }
\t		{ s_extend(5), s_add("%s", "  "); }
\"		{ s_extend(2); s_add("%s", "\\\""); }
.		{ s_extend(1+yyleng); s_add("%s", yytext); }
<<EOF>> { 
	if ( --include_stack_ptr < 0 ) {
		s_dump(yyout);
		yyterminate();
	}
	yy_delete_buffer( YY_CURRENT_BUFFER );
	yy_switch_to_buffer(include_stack[include_stack_ptr] );
	yylineno = include_lines[include_stack_ptr];
	strcpy(curfile, include_files[include_stack_ptr]);
}

<C>{cend}{ws}*{nl}* { s_extend(100);
	s_add("\n#line %d \"%s\"\nECHO(\"%%s\",\"", yylineno, curfile);
	BEGIN(INITIAL);
}
<C>{binclude}		{ BEGIN(BINCL); }
<C>[^%><]		{ s_extend(1+yyleng); s_add("%s", yytext); }
<C>[%><]		{ s_extend(2); s_add("%s", yytext); }

<IGNORE>{comend}{ws}*{nl}*	{ BEGIN(INITIAL); }
<IGNORE>.			;

<INCL,BINCL,INCLEND,BINCLEND>{ws}+	;
<INCL,BINCL,INCLEND,BINCLEND>{nl}+	;
<INCLEND>{comend}{ws}*{nl}*	{ 
	FILE *fp;
	if ( include_stack_ptr >= MAX_INCLUDE_DEPTH )
	{
		yyerror("includes are too deep, i drowned.");
		exit(1);
	}

	include_lines[include_stack_ptr ] = yylineno;
	include_stack[include_stack_ptr++] =
		YY_CURRENT_BUFFER;
	yylineno = 1;

	fp = fopen( curfile, "r" );

	BEGIN(INITIAL); 
	if ( fp ) {
		yy_switch_to_buffer(
			yy_create_buffer(fp, YY_BUF_SIZE));
		yyin = fp;
	}
	else {
		perror(curfile);
	}
}

<INCL>{name}+	{
	strcpy(include_files[include_stack_ptr], curfile );
	strcpy(curfile, yytext);
	/* you stop off the previous ECHO */
	s_add("\");\n#line 1 \"%s\"\n%s", curfile, "ECHO(\"%s\",\"");
	BEGIN(INCLEND);
}

<INCLEND>.  {
		yyerror("Adjacent includes not supported, for `%s'(yet?)", yytext);
		exit(1);
}

<BINCL>{comend} { BEGIN(C); }
<BINCL>{name}+ {
	FILE * fp = fopen(yytext, "rb");
	if (fp) {
		for( ;; ) {
			char buf[8];
			int c = getc (fp) ;
			if ( feof(fp )) 
				break;
			s_extend(snprintf(buf, sizeof(buf), "'\\x%02X', ", c ));
			s_add("%s", buf);
		}
		fclose(fp);
	}
	else {
		yyerror(yytext);
		exit(1);
	}
}

%%

#include <signal.h>
#include <stdarg.h>
#define S_DELTA 8192
static char *		s_buf = NULL;
static unsigned long 	s_len = 0;
static unsigned long 	s_pos = 0;


static void s_segv ( int k )  {
	fprintf(stderr, "sigseg at s_len=%lu, s_pos=%lu, yytext='%s', yylineno=%u\n",
		s_len, s_pos, yytext, yylineno);
	exit(-1);
}

static void s_extend(unsigned long by) {
	if ( s_len <= (s_pos + by)) {
		char *p;
		p = realloc(s_buf, s_len + S_DELTA);
		if ( !p ) {
			perror("s_extend");
			exit(-1);
		}
		s_buf = p;
		s_len += S_DELTA;
	}
}

static void s_add(const char *fmt, ...)
{ 
	va_list ap;
	va_start(ap, fmt);
	s_pos += vsnprintf(s_buf+s_pos, s_len-s_pos, fmt, ap);
	va_end(ap);
}

static void s_init(void) {
	s_extend(1);
	s_add("\n#line 1 \"%s\"\n%s", curfile, "ECHO(\"%s\",\"");
}

static void s_dump(FILE *fp)
{
	char *p = s_buf;
	s_extend(5); s_add("%s", "\");\n");
	for(p =strstr(p, "ECHO(\"%s\",\"\");"); p; p = strstr(p, "ECHO(\"%s\",\"\");"))
	{
		memcpy(p,"/* ignore me*/", 14);
	}
	fwrite(s_buf, s_pos, sizeof(char), fp);
}

int main(int argc, char **argv) {
	signal(SIGSEGV, s_segv);
	strcpy(curfile, "<stdin>");
	if ( argc > 1 ) {
		yyin = fopen (argv[1], "r");
		strcpy(curfile, argv[1]);
	}
	s_init();
	yylex();
}

static int yyerror(char *msg,...) {
	va_list ap;
	va_start(ap, msg);
	fprintf(stderr, "%s:%u:", curfile, yylineno);
	vfprintf(stderr, msg, ap);
	fputc('\n', stderr);
	if ( errno ) {
		perror(yytext);
	}
	return 0;
}
