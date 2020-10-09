/*
 [The "BSD licence"]
 Copyright (c) 2013 Terence Parr
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.
 3. The name of the author may not be used to endorse or promote products
    derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/** XML parser derived from ANTLR v4 ref guide book example */
parser grammar UppaalParser;
//check 275 page

@parser::members { // add members to generated UppaalParser
    private int num=0;

    public int getNum(){
        return this.num;
    }
    public void setNum(int num){
        this.num = num;
    }
}
options { tokenVocab=UppaalLexer; }

//document    :   prolog? misc* element misc*;

model       :   prolog? misc* nta misc* ;

prolog      :   XMLDeclOpen attribute* SPECIAL_CLOSE ;

content     :   chardata?
                ((element | reference | CDATA | PI | COMMENT) chardata?)* ;

element     :   '<' Name attribute* '>' content '</' Name '>'
            |   '<' Name attribute* '/>'
            ;

reference   :   EntityRef | CharRef ;

attribute   :   Name EQUALS STRING ; // Our STRING is AttValue in spec

/** ``All text that is not markup constitutes the character data of
 *  the document.''
 */
chardata    :   TEXT | SEA_WS ;

misc        :   COMMENT | PI | SEA_WS ;

nta         :   '<' 'nta' '>' misc*
                declaration misc*
                (template misc*)+
                system misc*
                (queries misc*)?
                '</' 'nta' '>' ;

//declaration :   '<' 'declaration' '>' anything '</' 'declaration' '>' ;

declaration :   OPEN_DECLARATION decl_content CLOSE_DECLARATION;

decl_content:   declarations* ;

declarations:   variableDecl    # VariableDeclaration
            |   typeDecl        # typeDeclaration
            |   function        # FunctionDeclaration
            |   chanPriority    # ChanDeclaration
            ;

expr        :   IDENTIFIER  # IdentifierExpr
            |   NAT         # NatExpr
            |   POINT       # DoubleExpr
            |   expr '[' guard_expr ']'   # ArrayExpr
            |   expr '\''     # StopWatchExpr
            |   '(' expr ')'  # ParenthesisExpr
            |   expr '++'     # ExprIncrement
            |   '++' expr     # IncrementExpr
            |   expr '--'     # ExprDecrement
            |   '--' expr     # DecrementExpr
            |   expr
                    //assign is '=' in guard channel
                    assign=(ASSIGN | ':=' | '+=' | '-=' | '*=' | '/=' | '%=' | '|=' | '&amp;=' | '^=' | '&lt;&lt;=' | '&gt;&gt;=')
                        expr  # AssignExpr
            |   unary=('-' | '+' | '!' | 'not') expr  # UnaryExpr
            |   expr binary=( '&lt;' | '&lt;=' | '==' | '!=' | '&gt;=' | '&gt;' //LESS is '<' in guard channel. Greater is '>' in guard channel
                                   ) expr     # ComparisonExpr
            |   expr binary=( '+' | '-' | '*' | '/' | '%' | '&amp;'
                                    |  '|' | '^' | '&lt;&lt;' | '&gt;&gt;' | '&amp;&amp;' | '||'
                                    |  '&lt;?' | '&gt;?' | 'or' | 'and' | 'imply')
                                    guard_expr      #BinaryExpr
            |   expr '?' expr ':' expr
                                    # IfExpr
            |   expr '.' IDENTIFIER   # DotExpr
            |   expr '(' guard_arguments ')'# FuncExpr
            |   'forall' '(' IDENTIFIER ':' type ')' expr     # ForallExpr
            |   'exists' '(' IDENTIFIER ':' type ')' expr     # ExistsExpr
            |   'sum' '(' IDENTIFIER ':' type ')' expr        # SumExpr
            |   'true'  # TrueExpr
            |   'false' # FalseExpr
            ;

variableDecl:   type variableID (',' variableID)* ';' ;

type        :   prefix? typeId ;

prefix      :   URGENT      # UrgentPrefix
            |   'broadcast' # BroadcastPrefix
            |   'meta'      # MetaPrefix
            |   'const'     # ConstPrefix
            ;

typeId      :   IDENTIFIER  # IdentifierType
            |   'int'       # IntType
            |   'double'    # DoubleType
            |   'clock'     # ClockType
            |   'chan'      # ChanType
            |   'bool'      # BoolType
            |   'int' '[' expr ',' expr ']'     # IntDomainType
            |   'scalar' '[' expr ']'           # ScalarType
            |   'struct' '{' (fieldDecl)+ '}'   # StructType
            ;

fieldDecl   :   type varFieldDecl (',' varFieldDecl)* ';' ;

varFieldDecl:   IDENTIFIER arrayDecl* ;

arrayDecl   :   '[' expr ']'    # ArrayDeclExpr
            |   '[' type ']'    # ArrayDeclType
            ;

variableID  :   IDENTIFIER arrayDecl* (ASSIGN initialiser )? ;

initialiser :   expr                                        # InitialiserExpr
            |   '{' initialiser (',' initialiser)* '}'      # InitialiserArray
            ;

//typeDecl    :   'typedef' type IDENTIFIER arrayDecl* (',' IDENTIFIER arrayDecl*)* ';' ;
typeDecl    :   'typedef' type varFieldDecl (',' varFieldDecl)* ';' ;

function    :   type IDENTIFIER '(' funcParameters ')' block ;

funcParameters: (funcParameter (',' funcParameter)*)? ;

//funcParameter:  type ('&amp;')? IDENTIFIER arrayDecl* ;
funcParameter:  type ('&amp;')? varFieldDecl ;

block       :   '{' decl_content statement* '}' ;

statement   :   block           # StatementBlock
            |   ';'             # StatementSemicolon
            |   expr ';'        # StatementExpr
            |   forLoop         # StatementFor
            |   iteration       # StatementIteration
            |   whileLoop       # StatementWhile
            |   doWhile         # StatementDoWhile
            |   ifStatement     # StatementIf
            |   returnStatement # StatementReturn
            ;

forLoop     :   'for' '(' expr ';' expr ';' expr ')' statement ;

iteration   :   'for' '(' IDENTIFIER ':' type ')' statement ;

whileLoop  :   'while' '(' expr ')' statement ;

doWhile    :   'do' statement 'while' '(' expr ')' ';' ;

ifStatement:   'if' '(' expr ')' statement ('else' statement)? ;

returnStatement: 'return' (expr)? ';' ;

chanPriority:  'chan' 'priority' chanOrDef (chanSeparator chanOrDef)* ';' ;

chanOrDef   :   (chanExpr | 'default' ) ;

chanSeparator:  (',' | '&lt;') ;

chanExpr    :   IDENTIFIER              # ChanIdentifier
            |   chanExpr '[' expr ']'   # ChanArray
            ;
////////////////////////////////////////////////////////////////////////////////
anything    :   chardata?
                ((reference | CDATA | PI | COMMENT) chardata?)* ;

template    :   '<' 'template' '>' misc* temp_content  '</' 'template' '>' ;

temp_content:   (name misc*)?
                (parameter misc*)?
                (declaration misc*)?

                ((location misc*) | (branchpoint misc*))+
                (init_loc misc*)
                (transition misc*)*;

parameter   :   OPEN_PARAMETER funcParameters CLOSE_PARAMETER ;

coordinate  :   'x' EQUALS STRING 'y' EQUALS STRING ;

init_loc    :   '<' 'init' 'ref' EQUALS STRING '/>' ;

branchpoint :   '<' 'branchpoint' 'id' EQUALS STRING
                    coordinate? '>' misc*
                    '</' 'branchpoint' '>';

location    :   '<' 'location' 'id' EQUALS STRING
                    coordinate? '>' misc* (name misc*)?
                    (label_loc misc*)*
                    ('<' (URGENT_LOC | 'committed') '/>' misc*)?

                    '</' 'location' '>' ;

label_loc   :   '<' 'label' 'kind' EQUALS STRING coordinate?  '>' anything '</' 'label' '>' ;

name        :   '<' 'name'
                    coordinate?
                    '>' anything '</' 'name' '>' ;

transition  :   '<' 'transition' '>'
                misc* (source misc*) (target misc*)
                (label_trans misc*)*
                (nail misc*)*
                '</' 'transition' '>' ;


//Are equals to labels_loc but we can manipulate them differently
label_trans :   OPEN_GUARD guard_expr? CLOSE_GUARD # LabelTransGuard
            |   '<' 'label' 'kind' EQUALS STRING coordinate?  '>' anything '</' 'label' '>' # labelTrans;


guard_expr  :   IDENTIFIER  # IdentifierGuard
            |   NAT   # NatGuard
            |   POINT    # DoubleGuard
            |   guard_expr '[' guard_expr ']'   # ArrayGuard
            |   guard_expr '\''     # StopWatchGuard
            |   '(' guard_expr ')'  # ParenthesisGuard
            |   guard_expr '++'     # GuardIncrement
            |   '++' guard_expr     # IncrementGuard
            |   guard_expr '--'     # GuardDecrement
            |   '--' guard_expr     # DecrementGuard
            |   guard_expr
                    //assign is '=' in guard channel
                    assign=(ASSIGN | ':=' | '+=' | '-=' | '*=' | '/=' | '%=' | '|=' | '&amp;=' | '^=' | '&lt;&lt;=' | '&gt;&gt;=')
                        guard_expr  # AssignGuard
            |   unary=('-' | '+' | '!' | 'not') guard_expr  # UnaryGuard
            |   guard_expr binary=( '&lt;' | '&lt;=' | '==' | '!=' | '&gt;=' | '&gt;' //LESS is '<' in guard channel. Greater is '>' in guard channel
                                   ) guard_expr
                {

                this.num++;
                //System.out.println ($binary.text);
                }
                                   # ComparisonGuard
            |   guard_expr binary=( '+' | '-' | '*' | '/' | '%' | '&amp;'
                                    |  '|' | '^' | '&lt;&lt;' | '&gt;&gt;' | '&amp;&amp;' | '||'
                                    |  '&lt;?' | '&gt;?' | 'or' | 'and' | 'imply')
                                    guard_expr   #BinaryGuard
            |   guard_expr '?' guard_expr ':' guard_expr
                                    # IfGuard
            |   guard_expr '.' IDENTIFIER   # DotGuard
            |   guard_expr '(' guard_arguments ')'# FuncGuard
            |   'forall' '(' IDENTIFIER ':' guard_type ')' guard_expr     # ForallGuard
            |   'exists' '(' IDENTIFIER ':' guard_type ')' guard_expr     # ExistsGuard
            |   'sum' '(' IDENTIFIER ':' guard_type ')' guard_expr        # SumGuard
            |   'true'  # TrueGuard
            |   'false' # FalseGuard
            ;

guard_arguments   :   (guard_expr  (',' guard_expr)*)? ;

guard_type        :   ('meta' | 'const')? guard_typeId ;

guard_typeId
            :   'int'                                       # GuardTypeInt
            |   'int' '[' guard_expr ',' guard_expr ']'     # GuardTypeIntDomain
            |   'scalar' '[' guard_expr ']'                 # GuardTypeScalar
            ;

source      :   '<' 'source' 'ref' EQUALS STRING '/>' ;

target      :   '<' 'target' 'ref' EQUALS STRING '/>' ;

nail        :   '<' 'nail' coordinate? '/>' ;

system      :   '<' 'system' '>' anything '</' 'system' '>' ;

queries     :   '<' 'queries' '>' misc* (query misc*)* '</' 'queries' '>' ;

query       :   '<' 'query' '>' misc* (formula misc*)? (comment misc*)? '</' 'query' '>' ;

formula     :   '<' 'formula' '>' anything '</' 'formula' '>' ;

comment     :   '<' 'comment' '>' anything '</' 'comment' '>' ;


//guard_expr  :   IDENTIFIER misc*;