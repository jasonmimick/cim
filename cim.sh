#!/bin/bash
# shell script load push and pull
# artifacts from Caché
#
# 
# Example:
# %>cim put _system:SYS@localhost:1234 /tmp/foo.Book.cls
# Loads the foo.Book.cls into localhost:1234
#
# %>cim get _system:SYS@localhost:1234 foo.Book.cls > /tmp/foo/Book.cls
# Get class from Caché and dumps to file
#

#
# TO-DO make bootstrap smarter where it can download 
# a new version of itself from github
#

# Download a new version of yourself-
update() 
{
    curl -v -X GET https://
}

bootstrap() 
{
username=$1
password=$2
namespace=$3
instance=$4
cache_home=$5
tmp="/tmp/cim.bootstrap.$RANDOM.xml"
cat <<'End-Of-Bootstrap' >> "$tmp"
<?xml version="1.0" encoding="UTF-8"?>
<Export generator="Cache" version="25" zv="Cache for UNIX (Apple Mac OS X for x86-64) 2013.1 (Build 446U)" ts="2013-06-21 14:26:34">
<Class name="cim.cim">
<Description><![CDATA[
HTTP handler to get and load Cache code artifacts
REST-style code manager

Used by the node.js code manager nostudio.js
which let's you do your coding in any old text editor you want
Accepts GET/POST HTTP verbs to manage
artifacts.
Supports the following artifacts - classes (.cls), mac/int routines (.mac/.int) and includes (.inc)
Returns errors and meta-data as JSON strings.

GET ?<artifact_name>
Returns the artifact or error

POST  
Content-Type: application/x-cache-<artifact type>

Use this to push code into Cache - you must specify your the Content-Type HTTP header
correctly based upon the kind of thing you're loading - cls/mac/int/inc

The name of the aritfact in Cache is determined by the thing itself
]]></Description>
<IncludeCode>%occReference,%occInclude</IncludeCode>
<ProcedureBlock>1</ProcedureBlock>
<Super>%CSP.Page</Super>
<TimeChanged>62994,51751.690955</TimeChanged>
<TimeCreated>62994,51216.230176</TimeCreated>

<Parameter name="CIMVERSION">
<Default>0.1</Default>
</Parameter>

<Parameter name="TAB">
<Type>%String</Type>
<Default> </Default>
</Parameter>

<Method name="outputDescription">
<ClassMethod>1</ClassMethod>
<FormalSpec>description</FormalSpec>
<Implementation><![CDATA[
	return:(""=description)
	for j=1:1:$length(description,$c(13,10)) {
		write "/// "_$p(description,$c(13,10),j),!
	}
]]></Implementation>
</Method>

<Method name="getModifiers">
<ClassMethod>1</ClassMethod>
<FormalSpec>object,modNamesList</FormalSpec>
<Implementation><![CDATA[
	
	set mods=""
	for i=1:1:$listlength(modNamesList) {
		set mod=$listget(modNamesList,i)
		//write "mod=",mod
		continue:""=mod
		set value=$property(object,mod)
		//write " value=",value,!!
		if ( "Constraint, Flags, Type, Data, SqlName, SqlComputeCode, SqlComputeOnChange" [ mod ) {
			if ( ""'=value ) {
				if ( mod="SqlComputeCode" ) {
					set value="{ "_value_" }"
				}
				set mods=mods_$lb(mod_"="_value)
			}
		} else {
			if ( value )  {
				set mods=mods_$lb(mod)
			}
		} 
	}
	//
	return:$ll(mods)=0 ""
	set mods="[ "_$listtostring(mods,", ")_" ]"
	return mods
]]></Implementation>
</Method>

<Method name="getParameters">
<ClassMethod>1</ClassMethod>
<FormalSpec>p</FormalSpec>
<Implementation><![CDATA[
	set ps=""
	if ( p.Parameters.Count() > 0 ) {
		set key=p.Parameters.Next("")
		set ps="("

		while ( key'="" ) {
			set value=p.Parameters.GetAt(key)
			set value=$replace(value,"""","""""")	
			set:value'?.N ps=ps_key_"="""_value_""""
			set:value?.N ps=ps_key_"="_value
				
			set key=p.Parameters.Next(key)
			if ( key'="" ) { set ps=ps_", " }	
		}
		set ps=ps_")"
	}
	return ps
]]></Implementation>
</Method>

<Method name="getClass">
<ClassMethod>1</ClassMethod>
<FormalSpec>name</FormalSpec>
<Implementation><![CDATA[
	set name=$$$NormalizeClassname(name)
	set name=$piece(name,".",1,$length(name,".")-1)
	//write "name=",name,!
	if ('$$$defClassDefined(name)) {
		write ..jp("error","Class "_name_" was not found")
		quit
	}
	#dim cdef As %Dictionary.ClassDefinition
	
	set cdef=##class(%Dictionary.ClassDefinition).%OpenId(name)
	//write """data"": ["
	//write ..cl("Class "_name_" Extends "_cdef.Super)
	set t="    " // tab =  spaces
	if ( $length(cdef.IncludeCode,",") > 1 ) {
		write "Include (",cdef.IncludeCode,")",!,!
	} else {
		if ( ""'=cdef.IncludeCode ) {
			write "Include ",cdef.IncludeCode,!,!
		}
	}
	
	// comments
	set comments=$get(^oddDEF(name,4))
	if ( ""'=comments ) {
		for i=1:1:$length(comments,$C(13,10)) {
			write "/// "_$piece(comments,$C(13,10),i),!
		}
	}
	
	set super=cdef.Super
	if ( $length(super,",")>1 ) {
		set super="("_super_")"
	}
	write "Class "_name_" Extends "_super
	write ..getModifiers(cdef,$lb())
	write !
	// TO-DO Gotta write out Modifiers()
	write "{",!,!
	
	// everything is ordered by SequenceNumber -
	// obvious from the documentation, right?
	kill order
	set things=$lb("UDLTexts","Parameters","Properties","Indices","Methods","Projections","Queries","XDatas")
	set i=0 while ( $listnext(things,i,thing) ) {
		set ot=$property(cdef,thing)
		for j=1:1:$method(ot,"Count") {
			set theThing = $method(ot,"GetAt",j)
			set seq=$property(theThing,"SequenceNumber")
			set order(seq,"t")=thing		// the kind of thing
			set order(seq,"o")=theThing		// the actual thing
		}
	}
	//zw order
	k ^ifoo
	m ^ifoo=order
	set i=$order(order(0))
	while ( i'="" ) {
		do $classmethod($this,order(i,"t")_"Out",order(i,"o"))	
		set i=$order(order(i))
	}
	
	write "}",!
]]></Implementation>
</Method>

<Method name="UDLTextsOut">
<ClassMethod>1</ClassMethod>
<FormalSpec>udl:%Dictionary.UDLTextDefinition</FormalSpec>
<Implementation><![CDATA[
	//write "Category=",u.Category," Name=",u.Name," TextType=",u.TextType," Position=",u.Position," SequenceNumber=",u.SequenceNumber,!
	do udl.Content.OutputToDevice()
]]></Implementation>
</Method>

<Method name="ParametersOut">
<ClassMethod>1</ClassMethod>
<FormalSpec>param:%Dictionary.ParameterDefinition</FormalSpec>
<Implementation><![CDATA[

		do ..outputDescription(param.Description)
		set mods=..getModifiers(param,$listbuild("Abstract","Final","Flags","Constraint"))
		if ( ""'=param.Default ) {
			set default=" = """_param.Default_""""
		} 
		if ( ""'=param.Expression ) {
			set default=" = {"_param.Expression_"}"
		}
		set type=" "
		if ( ""'=param.Type ) {
			set type=" As "_param.Type
		}
		write "Parameter "_param.Name_type_" "_mods_" "_$get(default)_";",!,!
]]></Implementation>
</Method>

<Method name="QueriesOut">
<ClassMethod>1</ClassMethod>
<FormalSpec>qry:%Dictionary.QueryDefinition</FormalSpec>
<Implementation><![CDATA[
	do ..outputDescription(qry.Description)
	set mods=..getModifiers(qry,$lb("SqlName","SqlProc","Final"))
	write "Query "_qry.Name_" As "
	write qry.Type,..getParameters(qry)
	write mods_";",!
	write ..#TAB,"{",!
	write ..#TAB,qry.SqlQuery,!
	write ..#TAB,"}",!
]]></Implementation>
</Method>

<Method name="PropertiesOut">
<ClassMethod>1</ClassMethod>
<FormalSpec>p:%Dictionary.PropertyDefinition</FormalSpec>
<Implementation><![CDATA[
	do ..outputDescription(p.Description)
	// "Cardinality","ClientName","InitialExpression","Inverse","OnDelete"
	set mods=..getModifiers(p,$lb("Calculated","Cardinality","ClientName","Final","Identity","InitialExpression","Internal","Inverse","MultiDimensional","OnDelete","Private","ReadOnly","Required","Transient","SqlComputeCode","SqlComputed","SqlComputeOnChange"))
	// Parameters
		
	// Collection
	write "Property "_p.Name_" As "
	if ( ""'=p.Collection ) {
		write p.Collection_" of "
	}
	write p.Type,..getParameters(p)
	write mods_";",!,!
]]></Implementation>
</Method>

<Method name="IndicesOut">
<ClassMethod>1</ClassMethod>
<FormalSpec>idx:%Dictionary.IndexDefinition</FormalSpec>
<Implementation><![CDATA[
	do ..outputDescription(idx.Description)
	write "Index ",idx.Name," On ",idx.Properties
	set mods=..getModifiers(idx,$lb("Data","Type","Unique","PrimaryKey","IdKey","Internal"))
	write:""'=mods " ",mods,";"
	write:""=mods ";"
	write !,!
]]></Implementation>
</Method>

<Method name="XDatasOut">
<ClassMethod>1</ClassMethod>
<FormalSpec>xd:%Dictionary.XDataDefinition</FormalSpec>
<Implementation><![CDATA[
	do ..outputDescription(xd.Description)
	write "XData ",xd.Name," {",!
	while ( 'xd.Data.AtEnd ) {
		write ..#TAB,..#TAB,xd.Data.ReadLine(),!
	}
	write ..#TAB,"}",!
]]></Implementation>
</Method>

<Method name="MethodsOut">
<ClassMethod>1</ClassMethod>
<FormalSpec>mdef:%Dictionary.MethodDefinition</FormalSpec>
<Implementation><![CDATA[
	if ( mdef.ClassMethod ) {
			set d="ClassMethod "
	} else {
		set d="Method "
	}
	set d=d_mdef.Name_"("_mdef.FormalSpec_") "
	if ( mdef.ReturnType'="" ) {
		set d=d_"As "_mdef.ReturnType
	}
	set mods=" "_..getModifiers(mdef,$lb("CodeMode","SqlName","SqlProc","Final","Abstract","Internal","WebMethod"))
	do ..outputDescription(mdef.Description)
	write d,mods,!,..#TAB,"{",!
		
	set impl=mdef.Implementation
	do mdef.Implementation.OutputToDevice()
		
	write ..#TAB,"}",!
	write !
]]></Implementation>
</Method>

<UDLText name="T">
<Content><![CDATA[
/*
// storage

// Storage implementation in %Dictionary.StorageDefinition sucks - there is no

// simple stream with the XML :)
#dim storage as %Dictionary.StorageDefinition
	for i=1:1:cdef.Storages.Count() {
		set storage=cdef.Storages.GetAt(i)
		write !,t,"/// Storage name=",storage.Name,!,!
		//if $d(storage.ExtentSize) {
		//	do ..wtag("ExtentSize",storage.ExtentSize)
		//}
}
*/
]]></Content>
</UDLText>

<Method name="wtag">
<ClassMethod>1</ClassMethod>
<FormalSpec>tag,value,end=1</FormalSpec>
<Implementation><![CDATA[
	// indent - but we don't need XML for our format!
	write "<"_tag_">"
	write value
	if ( end ) { write "</"_tag_">" }
	write !
]]></Implementation>
</Method>

<Method name="cl">
<ClassMethod>1</ClassMethod>
<CodeMode>expression</CodeMode>
<FormalSpec>line,addComma=1</FormalSpec>
<Implementation><![CDATA[..QuoteJS(line)_$S(addComma:",",1:"")
]]></Implementation>
</Method>

<Method name="getRoutine">
<ClassMethod>1</ClassMethod>
<FormalSpec>name</FormalSpec>
<Implementation><![CDATA[
	set rm=##class(%RoutineMgr).%New(name)
	//write """data"": ["
	while ( 'rm.Code.AtEnd ) {
		set line=rm.Code.ReadLine()
		write line,!
	}
	//write ..QuoteJS("__end__")
	//write "]"
]]></Implementation>
</Method>

<Method name="usage">
<ClassMethod>1</ClassMethod>
<Implementation><![CDATA[
	&html<
	<!DOCTYPE html>
		<head>
			<title>cim</title>
			<style>body { font-family: courier; font-size : 12 }</style>
		</head>
		<body>
			<h2>cim (#(..#CIMVERSION)#)</h2>
			<p>Cach&eacute code manager.</p>
			<p><a href="https://github.com/jasonmimick/cim">https://github.com/jasonmimick/cim</a></p>
		<body>
	</html>
	>
]]></Implementation>
</Method>

<Method name="get">
<ClassMethod>1</ClassMethod>
<Implementation><![CDATA[
	
	set artifactName=$order(%request.Data(""))
	//write " { "
	//write ..jp("name",artifactName)_", "
	set ext=$piece(artifactName,".",$length(artifactName,"."))
	//write ..jp("ext",ext)_", "
	if ( ""=artifactName ) {
		do ..usage()
		return
	}
	if ( ext="cls" ) {
		do ..getClass(artifactName)
	} elseif ( ext="mac"  ) {
		do ..getRoutine(artifactName)
	} elseif ( ext="int"  ) {
		do ..getRoutine(artifactName)
	} elseif ( ext="inc" ) {
		do ..getRoutine(artifactName)
	} else {
		write ..jp("error","Unknown extension")
	}
	//write " }"
	//write !
]]></Implementation>
</Method>

<Method name="jp">
<ClassMethod>1</ClassMethod>
<CodeMode>expression</CodeMode>
<FormalSpec>name,value</FormalSpec>
<Implementation><![CDATA[""""_name_""" : """_value_""""
]]></Implementation>
</Method>

<Method name="post">
<ClassMethod>1</ClassMethod>
<Implementation><![CDATA[
	// set contentType=..TryGuessContent()
	set ^foo($ZTS)=%request.ContentType
	m ^foo("fn")=%request.CgiEnvs
	set artifactName=$order(%request.Data(""))
	//set name=$$$NormalizeClassname(name)
	//set name=$piece(name,".",1,$length(name,".")-1)
	if ( %request.ContentType="application/x-cache-cls" ) {
		do ..postClassX()
	} elseif ( %request.ContentType="application/c-cache-mac" ) {
		do ..postMac(artifactName) 
	}
]]></Implementation>
</Method>

<Method name="postMac">
<ClassMethod>1</ClassMethod>
<Implementation><![CDATA[
	
	Set source=%request.Content
	Set rm=##class(%RoutineMgr).%New(routineName)
	while ( 'source.AtEnd ) {
		do rm.WriteLine(source.ReadLine)
	}
	do rm.%Save()
]]></Implementation>
</Method>

<Method name="OnPage">
<ClassMethod>1</ClassMethod>
<ReturnType>%Status</ReturnType>
<Implementation><![CDATA[
	#dim e as %Exception.AbstractException
	Set %response.ContentType = "application/json"
	set verb=%request.Method
	set result=$$$OK
	try {
		if ( verb = "GET" ) {
			do ..get()	
		} elseif ( verb = "POST" ) {
			do ..post()
		} else {
			write "{ error : """_verb_""" is not supported }"
		}
	} catch(e) {
		do e.OutputToDevice()
	}
	Quit $$$OK
]]></Implementation>
</Method>

<Method name="postClassX">
<ClassMethod>1</ClassMethod>
<Implementation><![CDATA[
	k ^||lines
	set source=%request.Content
	set source.LineTerminator=$C(10)
	while ( 'source.AtEnd ) {
		set line=source.ReadLine()
		set ^||lines($i(^||lines))=line
	}
	
	// possible word tokens
	set commentTokens=$lb("//","/*","///")
	
	set tokens=$lb("Class","Parameter","Property","Index","Query","Method","ClassMethod","XData")_commentTokens
	
	k ^||order
	for i=1:1:^||lines {
		// the first word of a line will tell us the type
		set line=^||lines(i)
		set firstWord = $zconvert($zconvert($piece(line," ",1),"L"),"S")		// lower then Sententce case
		set:firstWord="Classmethod" firstWord="ClassMethod"
		set:firstWord="Xdata" firstWord="XData"
		
		if ( $listfind(tokens,firstWord) = 0 ) {
			continue		// throw exception here???
		}
		if ( $listfind(commentTokens,firstWord) '= 0 ) {
			do ..UDLTextIn(i,.thing)
			set firstWord = "UDLText"
		} else {
			do $classmethod($this,firstWord_"In",.i,.thing)
		}
		set ^||order(i,"t")=firstWord
		set ^||order(i,"o")=thing
		if ( firstWord = "Class" ) {
			set classDef=thing
		} else {
			if ( $data(classDef) ) {
				set type=firstWord_"s"
				if ( type="Indexs" ) set type="Indice"
				if ( type="Propertys" ) set type="Properties"
				if ( type="ClassMethods" ) set type="Methods"
				if ( type="Querys" ) set type="Queries"
				set thing.SequenceNumber=$i(sequenceNumber)
				write type,!
				set collection=$property(classDef,type)
				do $method(collection,"Insert",thing)	
			}
		}
	}
	
	/*
	k ^foo,^ofoo
	merge ^foo=^||lines
	merge ^ofoo=^||order
	
	set i=^||order("Class"),sequenceNumber=0
	set classDef=^||order(i,"o"),i=$order(^||order(i))
	while ( i'="" ) {
		set type=^||order(i,"t")
		set thing=^||order(i,"o")
		w thing.Name
		set thing.SequenceNumber=$i(sequenceNumber)
		
		set i=$order(^||order(i))
	}
	*/
	
	if ( $data(^oddDEF(classDef.Name)) ) {
        do $system.OBJ.Delete( classDef.Name,"-d" )
    }
	//zw classDef
	
	set sc=classDef.%Save()
    if ($$$ISERR(sc) ) { do $system.OBJ.DisplayError(sc) }
    do $system.OBJ.Compile(classDef.Name,"-d")
]]></Implementation>
</Method>

<Method name="UDLTextIn">
<ClassMethod>1</ClassMethod>
<FormalSpec>i,*comment</FormalSpec>
<Implementation><![CDATA[
	set line=^||lines(i)
	set comment=##class(%Dictionary.UDLTextDefinition).%New()
	set comment.Category="comment",comment.Position="body"
	set comment.Name="T"_$i(^||lines("UDLTextCounter"))
	// TO-DO - need to read-ahead to support '/*' style comments
	if ( $extract($zstrip(line,"<W"),1,2)'="/*" ) {
		do comment.Content.WriteLine(line)
	} else { // we have a '/*' style comment
		set gotClose=0
		do comment.Content.WriteLine(line)
		while ( 'gotClose ) {
			if ( '$data(^||lines(i+1)) ) {
				// error!!
				write "ERROR i=",i,!
			}
			set line=^||lines($i(i))
			do comment.Content.WriteLine(line)
			if ( $extract($zstrip(line,">W"),*-1,*) = "*/" ) {
				set gotClose=1
			}
		}
	}
]]></Implementation>
</Method>

<Method name="ClassIn">
<ClassMethod>1</ClassMethod>
<FormalSpec>i,*cdef</FormalSpec>
<Implementation><![CDATA[
	set line=^||lines(i)
	set className = $piece(line," ",2)
	set supers = $piece(line," ",4)
	set cdef=##class(%Dictionary.ClassDefinition).%New()
	set cdef.Name=className
	set cdef.Super=supers
	do ..parseParams(line,.p)
	do ..setParams(cdef,.p)
	// any description?
	if ( $extract($get(^||lines(i-1)),1,3)="///") {
		set j=i-1,desc=""
		set l1=^||lines(j)
		while ( $extract(l1,1,3)="///" ) {
			set desc=desc_$e(l1,4,*),j=j-1,l1=$get(^||lines(j))
			if ( l1'="" ) { set desc=desc_$C(13,10) }	
		}
		set cdef.Description=desc
	}
	//return cdef
]]></Implementation>
</Method>

<Method name="ParameterIn">
<ClassMethod>1</ClassMethod>
<FormalSpec>i,*pdef</FormalSpec>
<Implementation><![CDATA[
	set line=^||lines(i)
	set pdef=##class(%Dictionary.ParameterDefinition).%New()
	set pdef.Name=$piece(line," ",2)
	set pdef.Type=$piece(line," ",4)
	do ..parseParams(line,.p)
	do ..setParams(pdef,.p)
	//return pdef
]]></Implementation>
</Method>

<Method name="parseParams">
<ClassMethod>1</ClassMethod>
<FormalSpec>line,*params</FormalSpec>
<Implementation><![CDATA[
	set l2=$piece($piece(line,"[",2),"]",1)
	set l3=$listfromstring(l2)
	for i=1:1:$listlength(l3) {
		set l4=$listfromstring($listget(l3,i),"=")
		set name=$zstrip($listget(l4,1),"<>W")
		set value=$zstrip($listget(l4,2),"<>W")
		set params(name)=value
	}
	zw params
]]></Implementation>
</Method>

<Method name="setParams">
<ClassMethod>1</ClassMethod>
<FormalSpec><![CDATA[object,&params]]></FormalSpec>
<Implementation><![CDATA[
	set n=$order(params(""))
	while ( n'="" ) {
		set v=params(n)
		set:v="" v=1
		set:..hasProperty(object,n) $property(object,n)=v
		set n=$order(params(n))
	}
]]></Implementation>
</Method>

<Method name="hasProperty">
<ClassMethod>1</ClassMethod>
<FormalSpec>object,propertyName</FormalSpec>
<Implementation><![CDATA[
	set cn=object.%ClassName(1)
	set cd=##class(%Dictionary.ClassDefinition).%OpenId(cn)
	for i=1:1:cd.Properties.Count() {
		if ( cd.Properties.GetAt(i).Name = propertyName ) {
			return 1
		}
	}
	return 0
]]></Implementation>
</Method>

<Method name="PropertyIn">
<ClassMethod>1</ClassMethod>
<FormalSpec>i,*pdef</FormalSpec>
<Implementation><![CDATA[
	set line=^||lines(i)
	w line,!
	set pdef=##class(%Dictionary.PropertyDefinition).%New()
	set pdef.Name=$piece(line," ",2)
	set pdef.Type=$piece($piece(line," ",4),";",1)
	do ..parseParams(line,.p)
	do ..setParams(pdef,.p)
	//return pdef
]]></Implementation>
</Method>

<Method name="IndexIn">
<ClassMethod>1</ClassMethod>
<FormalSpec>i,*idx</FormalSpec>
<Implementation><![CDATA[
	set line=^||lines(i)
	set idx=##class(%Dictionary.IndexDefinition).%New()
	set idx.Name=$piece(line," ",2)
	set idx.Type=$piece(line," ",4)
	do ..parseParams(line,.p)
	do ..setParams(idx,.p)
	//return idx
]]></Implementation>
</Method>

<Method name="QueryIn">
<ClassMethod>1</ClassMethod>
<FormalSpec>i,*qry</FormalSpec>
<Implementation><![CDATA[
	set line=^||lines(i)
	set qry=##class(%Dictionary.QueryDefinition).%New()
	set qry.Name=$piece($piece(line," ",2),"(",1)
	set returnType=""
    if ( $zconvert(line,"L")["as" ) {   // if there is a return type
    	// 1st space piece of 2nd as piece
    	set l1=$piece(line,")",2)
    	for l2="as","As","aS","AS" {
	    	set l1=$replace(l1," "_l2_" "," as ")
    	}
    	set returnType=$piece($piece(l1," as ",2)," ",1)
    	
    }
	set qry.Type=returnType
	do ..parseParams(line,.p)
	do ..setParams(qry,.p)
	// get body like method
	while ( line '[ "{" ) { set line=^||lines($i(i)) }
	set line=^||lines($i(i)),sql=""
	while ( line '[ "}" ) {
		set sql=sql_line_$C(13,10)
		set line=^||lines($i(i))
	}
	write sql,!
	set qry.SqlQuery=sql
	//return qry
]]></Implementation>
</Method>

<Method name="MethodIn">
<ClassMethod>1</ClassMethod>
<FormalSpec>i,*method</FormalSpec>
<Implementation><![CDATA[
	set line=^||lines(i)
	set line=$piece(line,"{",1)
    set line=$zstrip(line,">W")
     
	set method=##class(%Dictionary.MethodDefinition).%New()
	set m1=$piece(line,")",1)
   	set methodNameAndSignature=$piece(m1," ",2,$l(m1," "))
    set methodName=$piece(methodNameAndSignature,"(",1)
    set method.Name=methodName
    set formalSpec=$piece($piece(methodNameAndSignature,"(",2),")",1)
    set method.FormalSpec = ..translateFormalSpec(formalSpec)
    set returnType=""
    if ( $zconvert(line,"L")["as" ) {   // if there is a return type
    	// 1st space piece of 2nd as piece
    	set l1=$piece(line,")",2)
    	for l2="as","As","aS","AS" {
	    	set l1=$replace(l1," "_l2_" "," as ")
    	}
    	write "l1=",l1,!
    	set returnType=$piece($piece(l1," as ",2)," ",1)
    	write "returnType=",returnType,!
    	//set returnType=$piece(line," ",$length(line," "))
    }
    set method.FormalSpec=formalSpec
    set method.ReturnType=returnType
 	do ..parseParams(line,.p)
	do ..setParams(method,.p)
    // read in implementation
    set done=1
    while ( done'=0 ) {
    	set i=i+1
    	set cl=^||lines(i)
        if ( cl["{" ) { set done=done+1 }
        if ( cl["}" ) { set done=done-1 }
        if ( done'=0 ) {
			do method.Implementation.WriteLine(cl)
        }
    }
    //return method
]]></Implementation>
</Method>

<Method name="ClassMethodIn">
<ClassMethod>1</ClassMethod>
<FormalSpec>i,*method</FormalSpec>
<Implementation><![CDATA[
	do ..MethodIn(.i,.method)
	set method.ClassMethod=1
	//return method
]]></Implementation>
</Method>

<Method name="XDataIn">
<ClassMethod>1</ClassMethod>
<FormalSpec>i,*xdata</FormalSpec>
<Implementation><![CDATA[
	set xdata=##class(%Dictionary.XDataDefinition).%New()
	set name="FOOOOO"
	set xdata.Name=name
]]></Implementation>
</Method>

<Method name="postClass">
<ClassMethod>1</ClassMethod>
<Implementation><![CDATA[
    set source=%request.Content
    do %request.Content.OutputToDevice()
    set %request.Content.LineTerminator=$C(10)
    set gotEOF=0
    while ( 'source.AtEnd ) {
   
        set line = source.ReadLine()
       
        set ^foo($i(^foo))=line
        set line=$zstrip(line,"<W")
        set lineType = $zconvert($piece(line," ",1),"L")
        if ( lineType="class") {
            set className = $piece(line," ",2)
            set supers = $piece(line," ",4)
            set cdef("className")=className
            set cdef("supers")=supers
            continue
        }
        // TO-DO deal with attributes in []'s
        if ( lineType="property") {
            set pi=$i(cdef("properties"))
            set line=$p(line,";",1)
            set propName=$piece(line," ",2)
            set type=$piece(line," ",4)
            set cdef("properties",pi,"propName")=propName
            set cdef("properties",pi,"type")=type
            continue
        }
        if ( (lineType="method") || (lineType="classmethod") ) {
            set lt=lineType_"s"
            set mi=$i(cdef(lt))
            set line=$piece(line,"{",1)
            set line=$zstrip(line,">W")
            set m1=$piece(line,")",1)
            set methodNameAndSignature=$piece(m1," ",2,$l(m1," "))
            set methodName=$piece(methodNameAndSignature,"(",1)
            set formalSpec=$piece($piece(methodNameAndSignature,"(",2),")",1)
            set returnType=""
            if ( $zconvert(line,"L")["as" ) {   // if there is a return type
                set returnType=$piece(line," ",$length(line," "))
            }
            set cdef(lt,mi,"methodName")=methodName
            set cdef(lt,mi,"formalSpec")=formalSpec
            set cdef(lt,mi,"returnType")=returnType
            // read in implementation
            set done=1
            k cls
            while ( done'=0 ) {
                // throw if source.AtEnd pops up
                set cl=source.ReadLine()
                if ( cl["{" ) { set done=done+1 }
                if ( cl["}" ) { set done=done-1 }
                if ( done'=0 ) {
                    set i=$i(cls)
                    set cls(i)=cl
                }
            }
            if ( $data(cls) ) {
                merge cdef(lt,mi,"implementation")=cls
            }
        }
        if ( lineType="parameter" ) {
        }
        if ( lineType="classmethod" ) {
        }
    }
    // TO-DO pre-process cdef array to check to validity
    //zw cdef
    // generate the class
    if ( $data(^oddDEF(cdef("className")) )) {
        do $system.OBJ.Delete( cdef("className"),"-d" )
    }
    set classDef=##class(%Dictionary.ClassDefinition).%New(cdef("className"))
    set classDef.Name = cdef("className")
    set classDef.ProcedureBlock = 1
    set classDef.Super = cdef("supers")
    for i=1:1:cdef("properties") {
        set pdef=##class(%Dictionary.PropertyDefinition).%New()
        set pdef.Name = cdef("properties",i,"propName")
        set pdef.Type = cdef("properties",i,"type")
        do classDef.Properties.Insert(pdef)
    }
    merge ^foo("cdef")=cdef
    for mtype="methods","classmethods" {
        for i=1:1:cdef(mtype) {
            set mdef=##class(%Dictionary.MethodDefinition).%New()
            set mdef.Name = cdef(mtype,i,"methodName")
            set mdef.ReturnType = cdef(mtype,i,"returnType")
            set mdef.FormalSpec = ..translateFormalSpec(cdef(mtype,i,"formalSpec"))
            set codeStream = ##class(%Stream.TmpCharacter).%New()
            for j=1:1:cdef(mtype,i,"implementation") {
                do codeStream.WriteLine( cdef(mtype,i,"implementation",j) )
            }
            do codeStream.Rewind()
            set mdef.Implementation = codeStream
            do classDef.Methods.Insert(mdef)
        }
    }
    set sc=classDef.%Save()
    if ($$$ISERR(sc) ) { zw sc }
    do $system.OBJ.Compile(classDef.Name,"-d")
    zw classDef
    return 1
]]></Implementation>
</Method>

<Method name="translateFormalSpec">
<ClassMethod>1</ClassMethod>
<FormalSpec>in</FormalSpec>
<ReturnType>%String</ReturnType>
<Implementation><![CDATA[
	// Name As %String, Age As %Integer
    // to Name:%String,Age:%Integer
    set out=in
    for output="output ","Output ","OUTPUT " {
        set out=$replace(out,output,"*")
    }
    for byref="byref ","ByRef ","BYREF " {
        set out=$replace(out,byref,"&")
    }
    for as=" as "," As "," aS "," AS " {
        set out=$replace(out,as,":")
    }
    return out
]]></Implementation>
</Method>
</Class>
</Export>
End-Of-Bootstrap

csession="$cache_home/bin/csession"
# uppercase on namespace, since we expect on the prompt
namespace="`echo $namespace | tr '[:lower:]' '[:upper:']`"
system="\\\$system"
/usr/bin/expect <<End-Of-Expect
spawn $csession $instance -U $namespace
expect "Username: " {
    send "$username\r"
}
expect "Password: " {
    send "$password\r"
}
expect "$namespace>" {
    send "do $system.OBJ.Load(\"$tmp\",\"ck\")\r"
    expect "$namespace>"
    send "halt\r"
}
End-Of-Expect

rm $tmp
}

usage()
{
cat << 'End-Of-Usage'
cim - Caché artifact loader. Now you can use any old text editor with Caché.

Usage: cim [help|get|put|bootstrap] <user>:<password>@<server>:<port> <namespace> args

    help        - Displays this usage help
    get         - Gets code artifacts from Caché, like classes or routines
    put         - Loads code into Caché
    bootstrap   - Loads a class into Caché to enable get & put

Examples:
    To pull down the Sample.Person class from a default installation:

    cim get _system:SYS@localhost:57774 samples Sample.Person.cls
    
    this would save the class as a file called 'Sample.Person.cls' in the 
    current directory.

    You can then edit the class and load it back into Caché with:

    cim put _system:SYS@localhost:57774 samples ./Sample.Person.cls

    Use output redirection to save artifacts to different locations.
    The 'bootstrap' action requires additional arguments. For example,

    cim bootstrap _system:SYS@localhost:57774 samples MYCACHE /var/isc/mycache

    Would load the prerequisits to the 'samples' namespace on the 'MYCACHE'
    instance installed in '/var/isc/mycache'. The bootstrap mechanism falls back 
    to the standard $system.OBJ.Load() xml file process and thus needs to know 
    where to find things like 'csession'.
End-Of-Usage
}

action="$1"
connection="$2"
namespace="$3"
file="$4"

if [ $action = 'help' ]; then
    usage
    exit
fi
if [ $action = 'bootstrap' ]; then
    instance=$4
    cache_home=$5
    credentials=${connection%@*}
    username=${credentials%:*}
    password=${credentials#*:}
    #echo "credentials=$credentials username=$username password=$password"
    bootstrap $username $password $namespace $instance $cache_home
    exit
fi
if [ $action = 'get' ]; then
  curl -X GET http://$connection/csp/$namespace/cim.cim.cls?$file
  exit
fi
if [ $action = 'put' ]; then
 curl -v -X POST --data-binary @$file http://$connection/csp/$namespace/cim.cim.cls --header "Content-Type:application/x-cache-cls; charset=utf-8"

fi

#need to do header ???
#
# Bootstrap the loader call with a heredoc 


