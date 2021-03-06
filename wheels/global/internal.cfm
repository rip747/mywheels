<cffunction name="$listClean" returntype="any" access="public" output="false" hint="removes whitespace between list elements. optional argument to return the list as an array.">
	<cfargument name="list" type="string" required="true">
	<cfargument name="delim" type="string" required="false" default=",">
	<cfargument name="returnAs" type="string" required="false" default="string">
	<cfset var loc = {}>
	<cfset loc.list = ListToArray(arguments.list, arguments.delim)>
	<cfset loc.iEnd = ArrayLen(loc.list)>
	<cfloop from="1" to="#loc.iEnd#" index="loc.i">
		<cfset loc.list[loc.i] = trim(loc.list[loc.i])>
	</cfloop>
	<cfif arguments.returnAs eq "array">
		<cfreturn loc.list>
	</cfif>
	<cfreturn ArrayToList(loc.list, arguments.delim)>
</cffunction>

<cffunction name="$hashedKey" returntype="string" access="public" output="false">
	<cfscript>
		var loc = {};
		loc.returnValue = "";

		for (loc.key in arguments)
		{
			loc.value = arguments[loc.key];
			// SerializeJason crashes if a query contains binary data
			// a workaround is to use the underline meta information
			// to build the hash
			// this information was gathered from
			// http://www.silverwareconsulting.com/index.cfm/2009/1/20/Capturing-the-SQL-Generated-by-CFQUERY
			if(IsQuery(loc.value))
			{
				if (StructKeyExists(server, "railo"))
					loc.value = loc.value.getSQL().toString();
				else
					loc.value = loc.value.getMetaData().getExtendedMetaData();
			}
			if (IsSimpleValue(loc.value))
				loc.returnValue = loc.returnValue & loc.value;
			else
				loc.returnValue = loc.returnValue & ListSort(ReplaceList(SerializeJSON(loc.value), "{,}", ","), "text");
		}
		return Hash(loc.returnValue);
	</cfscript>
</cffunction>

<cffunction name="$timeSpanForCache" returntype="any" access="public" output="false">
	<cfargument name="cache" type="any" required="true">
	<cfargument name="defaultCacheTime" type="numeric" required="false" default="#application.wheels.defaultCacheTime#">
	<cfargument name="cacheDatePart" type="string" required="false" default="#application.wheels.cacheDatePart#">
	<cfscript>
		var loc = {};
		loc.cache = arguments.defaultCacheTime;
		if (IsNumeric(arguments.cache))
			loc.cache = arguments.cache;
		loc.list = "0,0,0,0";
		loc.dateParts = "d,h,n,s";
		loc.iEnd = ListLen(loc.dateParts);
		for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
			if (arguments.cacheDatePart == ListGetAt(loc.dateParts, loc.i))
				loc.list = ListSetAt(loc.list, loc.i, loc.cache);
		return CreateTimeSpan(ListGetAt(loc.list, 1),ListGetAt(loc.list, 2),ListGetAt(loc.list, 3),ListGetAt(loc.list, 4));
	</cfscript>
</cffunction>

<cffunction name="$combineArguments" returntype="void" access="public" output="false">
	<cfargument name="args" type="struct" required="true">
	<cfargument name="combine" type="string" required="true">
	<cfargument name="required" type="boolean" required="false" default="false">
	<cfargument name="extendedInfo" type="string" required="false" default="">
	<cfscript>
		if (StructKeyExists(arguments.args, ListGetAt(arguments.combine, 2)))
		{
			arguments.args[ListGetAt(arguments.combine, 1)] = arguments.args[ListGetAt(arguments.combine, 2)];
			StructDelete(arguments.args, ListGetAt(arguments.combine, 2));
		}
		if (arguments.required && application.wheels.showErrorInformation)
		{
			if (!StructKeyExists(arguments.args, ListGetAt(arguments.combine, 2)) && !Len(arguments.args[ListGetAt(arguments.combine, 1)]))
			{
				$throw(type="Wheels.IncorrectArguments", message="The `#ListGetAt(arguments.combine, 2)#` or `#ListGetAt(arguments.combine, 1)#` argument is required but was not passed in.", extendedInfo="#arguments.extendedInfo#");
			}
		}
	</cfscript>
</cffunction>

<!--- helper method to recursively map a structure to build mapping paths and retrieve its values so you can have your way with a deeply nested structure --->
<cffunction name="$mapStruct" returntype="void" access="public" output="false" mixin="dispatch">
	<cfargument name="map" type="struct" required="true" />
	<cfargument name="struct" type="struct" required="true" />
	<cfargument name="path" type="string" required="false" default="" />
	<cfscript>
		var loc = {};
		for (loc.item in arguments.struct)
		{
			if (IsStruct(arguments.struct[loc.item])) // go further down the rabit hole
			{
				$mapStruct(map=arguments.map, struct=arguments.struct[loc.item], path="#arguments.path#[#loc.item#]");
			}
			else // map our position and value
			{
				arguments.map["#arguments.path#[#loc.item#]"] = {};
				arguments.map["#arguments.path#[#loc.item#]"].value = arguments.struct[loc.item];
			}
		}
	</cfscript>
</cffunction>

<!--- convert an array to a structure --->
<cffunction name="$arrayToStruct" returntype="struct" access="public" output="false">
	<cfargument name="array" type="array" required="true" />
	<cfscript>
		var loc = {};
		loc.struct = {};
		loc.iEnd = ArrayLen(arguments.array);
		for (loc.i = 1; loc.i lte loc.iEnd; loc.i++)
			loc.struct[loc.i] = arguments.array[loc.i];
	</cfscript>
	<cfreturn loc.struct />
</cffunction>

<cffunction name="$structKeysExist" returntype="boolean" access="public" output="false" hint="Check to see if all keys in the list exist for the structure and have length.">
	<cfargument name="struct" type="struct" required="true" />
	<cfargument name="keys" type="string" required="false" default="" />
	<cfscript>
		var loc = {};
		loc.returnValue = true;
		loc.iEnd = ListLen(arguments.keys);
		for (loc.i = 1; loc.i lte loc.iEnd; loc.i++)
		{
			if (!StructKeyExists(arguments.struct, ListGetAt(arguments.keys, loc.i)) || (IsSimpleValue(arguments.struct[ListGetAt(arguments.keys, loc.i)]) && !Len(arguments.struct[ListGetAt(arguments.keys, loc.i)])))
			{
				loc.returnValue = false;
				break;
			}
		}
	</cfscript>
	<cfreturn loc.returnValue />
</cffunction>

<cffunction name="$hyphenize" returntype="string" access="public" output="false" hint="Converts camelcase strings to lowercase strings with hyphens instead. Example: `myVariable` becomes `my-variable`.">
	<cfargument name="string" type="string" required="true" hint="The string to hyphenize.">
	<cfreturn LCase(REReplace(REReplace(arguments.string, "([A-Z])", "-\l\1", "all"), "^-", "", "one"))>
</cffunction>

<cffunction name="$cgiScope" returntype="struct" access="public" output="false" hint="This copies all the variables Wheels needs from the CGI scope to the request scope.">
	<cfargument name="keys" type="string" required="false" default="request_method,http_x_requested_with,http_referer,server_name,path_info,script_name,query_string,remote_addr,server_port,server_port_secure,server_protocol,http_host,content_type">
	<cfscript>
		var loc = {};
		loc.returnValue = {};
		loc.iEnd = ListLen(arguments.keys);
		for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
			loc.returnValue[ListGetAt(arguments.keys, loc.i)] = cgi[ListGetAt(arguments.keys, loc.i)];
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="$dollarify" returntype="struct" access="public" output="false">
	<cfargument name="input" type="struct" required="true">
	<cfargument name="on" type="string" required="true">
	<cfscript>
		var loc = {};
		for (loc.key in arguments.input)
		{
			if (ListFindNoCase(arguments.on, loc.key))
			{
				arguments.input["$"&loc.key] = arguments.input[loc.key];
				StructDelete(arguments.input, loc.key);
			}
		}
	</cfscript>
	<cfreturn arguments.input>
</cffunction>

<cffunction name="$abortInvalidRequest" returntype="void" access="public" output="false">
	<cfscript>
		var applicationPath = Replace(GetCurrentTemplatePath(), "\", "/", "all");
		var callingPath = Replace(GetBaseTemplatePath(), "\", "/", "all");
		if (ListLen(callingPath, "/") GT ListLen(applicationPath, "/") || GetFileFromPath(callingPath) == "root.cfm")
		{
			$header(statusCode="404", statusText="Not Found");
			$includeAndOutput(template="#application.wheels.eventPath#/onmissingtemplate.cfm");
			$abort();
		}
	</cfscript>
</cffunction>

<cffunction name="$URLEncode" returntype="string" access="public" output="false">
	<cfargument name="param" type="string" required="false" default="">
	<cfscript>
		var returnValue = "";
		returnValue = URLEncodedFormat(arguments.param);
		returnValue = ReplaceList(returnValue, "%24,%2D,%5F,%2E,%2B,%21,%2A,%27,%28,%29", "$,-,_,.,+,!,*,',(,)"); // these characters are safe so set them back to their original values.
	</cfscript>
	<cfreturn returnValue>
</cffunction>

<cffunction name="$routeVariables" returntype="string" access="public" output="false">
	<cfscript>
		var loc = {};
		loc.route = $findRoute(argumentCollection=arguments);
		loc.returnValue = loc.route.variables;
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="$findRoute" returntype="struct" access="public" output="false">
	<cfscript>
		var loc = {};

		// throw an error if a route with this name has not been set by developer in the config/routes.cfm file
		if (application.wheels.showErrorInformation && !StructKeyExists(application.wheels.namedRoutePositions, arguments.route))
			$throw(type="Wheels.RouteNotFound", message="Could not find the `#arguments.route#` route.", extendedInfo="Create a new route in `config/routes.cfm` with the name `#arguments.route#`.");

		loc.routePos = application.wheels.namedRoutePositions[arguments.route];
		if (loc.routePos Contains ",")
		{
			// there are several routes with this name so we need to figure out which one to use by checking the passed in arguments
			loc.iEnd = ListLen(loc.routePos);
			for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
			{
				loc.returnValue = application.wheels.routes[ListGetAt(loc.routePos, loc.i)];
				loc.foundRoute = true;
				loc.jEnd = ListLen(loc.returnValue.variables);
				for (loc.j=1; loc.j <= loc.jEnd; loc.j++)
				{
					loc.variable = ListGetAt(loc.returnValue.variables, loc.j);
					if (!StructKeyExists(arguments, loc.variable) || !Len(arguments[loc.variable]))
						loc.foundRoute = false;
				}
				if (loc.foundRoute)
					break;
			}
		}
		else
		{
			loc.returnValue = application.wheels.routes[loc.routePos];
		}
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="$cachedModelClassExists" returntype="any" access="public" output="false">
	<cfargument name="name" type="string" required="true">
	<cfscript>
		var returnValue = false;
		if (StructKeyExists(application.wheels.models, arguments.name))
			returnValue = application.wheels.models[arguments.name];
	</cfscript>
	<cfreturn returnValue>
</cffunction>

<cffunction name="$constructParams" returntype="string" access="public" output="false">
	<cfargument name="params" type="string" required="true">
	<cfargument name="$URLRewriting" type="string" required="false" default="#application.wheels.URLRewriting#">
	<cfscript>
		var loc = {};
		arguments.params = Replace(arguments.params, "&amp;", "&", "all"); // change to using ampersand so we can use it as a list delim below and so we don't "double replace" the ampersand below
		// when rewriting is off we will already have "?controller=" etc in the url so we have to continue with an ampersand
		if (arguments.$URLRewriting == "Off")
			loc.delim = "&";
		else
			loc.delim = "?";
		loc.returnValue = "";
		loc.iEnd = ListLen(arguments.params, "&");
		for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
		{
			loc.temp = listToArray(ListGetAt(arguments.params, loc.i, "&"), "=");
			loc.returnValue = loc.returnValue & loc.delim & loc.temp[1] & "=";
			loc.delim = "&";
			if (ArrayLen(loc.temp) == 2)
			{
				loc.param = $URLEncode(loc.temp[2]);
				if (application.wheels.obfuscateUrls && !ListFindNoCase("cfid,cftoken", loc.temp[1]))
					loc.param = obfuscateParam(loc.param);
				loc.returnValue = loc.returnValue & loc.param;
			}
		}
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="$args" returntype="void" access="public" output="false">
	<cfargument name="args" type="struct" required="true">
	<cfargument name="name" type="string" required="true">
	<cfargument name="reserved" type="string" required="false" default="">
	<cfargument name="combine" type="string" required="false" default="">
	<cfscript>
		var loc = {};
		if (Len(arguments.combine))
		{
			loc.iEnd = ListLen(arguments.combine);
			for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
			{
				loc.item = ListGetAt(arguments.combine, loc.i);
				loc.first = ListGetAt(loc.item, 1, "/");
				loc.second = ListGetAt(loc.item, 2, "/");
				loc.required = false;
				if (ListLen(loc.item, "/") > 2)
				{
					loc.required = true;
				}
				$combineArguments(args=arguments.args, combine="#loc.first#,#loc.second#", required=loc.required);
			}
		}
		if (application.wheels.showErrorInformation)
		{
			if (ListLen(arguments.reserved))
			{
				loc.iEnd = ListLen(arguments.reserved);
				for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
				{
					loc.item = ListGetAt(arguments.reserved, loc.i);
					if (StructKeyExists(arguments.args, loc.item))
						$throw(type="Wheels.IncorrectArguments", message="The `#loc.item#` argument cannot be passed in since it will be set automatically by Wheels.");
				}
			}
		}
		if (StructKeyExists(application.wheels.functions, arguments.name))
			StructAppend(arguments.args, application.wheels.functions[arguments.name], false);
	</cfscript>
</cffunction>

<cffunction name="$createObjectFromRoot" returntype="any" access="public" output="false">
	<cfargument name="path" type="string" required="true">
	<cfargument name="fileName" type="string" required="true">
	<cfargument name="method" type="string" required="true">
	<cfscript>
		var returnValue = "";
		arguments.returnVariable = "returnValue";
		arguments.component = arguments.path & "." & arguments.fileName;
		StructDelete(arguments, "path");
		StructDelete(arguments, "fileName");
	</cfscript>
	<cfinclude template="../../root.cfm">
	<cfreturn returnValue>
</cffunction>

<cffunction name="$debugPoint" returntype="void" access="public" output="false">
	<cfargument name="name" type="string" required="true">
	<cfscript>
		var loc = {};
		if (!StructKeyExists(request.wheels, "execution"))
			request.wheels.execution = {};
		loc.iEnd = ListLen(arguments.name);
		for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
		{
			loc.item = ListGetAt(arguments.name, loc.i);
			if (StructKeyExists(request.wheels.execution, loc.item))
				request.wheels.execution[loc.item] = GetTickCount() - request.wheels.execution[loc.item];
			else
				request.wheels.execution[loc.item] = GetTickCount();
		}
	</cfscript>
</cffunction>

<cffunction name="$cachedControllerClassExists" returntype="any" access="public" output="false">
	<cfargument name="name" type="string" required="true">
		<cfscript>
			var returnValue = false;
			if (StructKeyExists(application.wheels.controllers, arguments.name))
				returnValue = application.wheels.controllers[arguments.name];
		</cfscript>
	<cfreturn returnValue>
</cffunction>

<cffunction name="$controllerFileName" returntype="string" access="public" output="false">
	<cfargument name="name" type="string" required="true">
	<cfscript>
		var loc = {};
		loc.controllerFileExists = false;
		if (!ListFindNoCase(application.wheels.existingControllerFiles, arguments.name) && !ListFindNoCase(application.wheels.nonExistingControllerFiles, arguments.name))
		{
			if (FileExists(ExpandPath("#application.wheels.controllerPath#/#capitalize(arguments.name)#.cfc")))
				loc.controllerFileExists = true;
			if (application.wheels.cacheFileChecking)
			{
				if (loc.controllerFileExists)
					application.wheels.existingControllerFiles = ListAppend(application.wheels.existingControllerFiles, arguments.name);
				else
					application.wheels.nonExistingControllerFiles = ListAppend(application.wheels.nonExistingControllerFiles, arguments.name);
			}
		}
		if (ListFindNoCase(application.wheels.existingControllerFiles, arguments.name) || loc.controllerFileExists)
			loc.returnValue = capitalize(arguments.name);
		else
			loc.returnValue = "Controller";
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="$createControllerClass" returntype="any" access="public" output="false">
	<cfargument name="name" type="string" required="true">
	<cfscript>
		var loc = {};
		application.wheels.controllers[arguments.name] = $createObjectFromRoot(path=application.wheels.controllerPath, fileName=$controllerFileName(arguments.name), method="$initControllerClass", name=arguments.name);
		loc.returnValue = application.wheels.controllers[arguments.name];
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="$controller" returntype="any" access="public" output="false">
	<cfargument name="name" type="string" required="true">
	<cfscript>
		var returnValue = "";
		returnValue = $doubleCheckedLock(name="controllerLock", condition="$cachedControllerClassExists", execute="$createControllerClass", conditionArgs=arguments, executeArgs=arguments);
	</cfscript>
	<cfreturn returnValue>
</cffunction>

<cffunction name="$addToCache" returntype="void" access="public" output="false">
	<cfargument name="key" type="string" required="true">
	<cfargument name="value" type="any" required="true">
	<cfargument name="time" type="numeric" required="false" default="#application.wheels.defaultCacheTime#">
	<cfargument name="category" type="string" required="false" default="main">
	<cfscript>
		var loc = {};
		if (application.wheels.cacheCullPercentage > 0 && application.wheels.cacheLastCulledAt < DateAdd("n", -application.wheels.cacheCullInterval, Now()) && $cacheCount() >= application.wheels.maximumItemsToCache)
		{
			// cache is full so flush out expired items from this cache to make more room if possible
			loc.deletedItems = 0;
			loc.cacheCount = $cacheCount();
			for (loc.key in application.wheels.cache[arguments.category])
			{
				if (Now() > application.wheels.cache[arguments.category][loc.key].expiresAt)
				{
					$removeFromCache(key=loc.key, category=arguments.category);
					if (application.wheels.cacheCullPercentage < 100)
					{
						loc.deletedItems++;
						loc.percentageDeleted = (loc.deletedItems / loc.cacheCount) * 100;
						if (loc.percentageDeleted >= application.wheels.cacheCullPercentage)
							break;
					}
				}
			}
			application.wheels.cacheLastCulledAt = Now();
		}
		if ($cacheCount() < application.wheels.maximumItemsToCache)
		{
			application.wheels.cache[arguments.category][arguments.key] = {};
			application.wheels.cache[arguments.category][arguments.key].expiresAt = DateAdd(application.wheels.cacheDatePart, arguments.time, Now());
			if (IsSimpleValue(arguments.value))
				application.wheels.cache[arguments.category][arguments.key].value = arguments.value;
			else
				application.wheels.cache[arguments.category][arguments.key].value = duplicate(arguments.value);
		}
	</cfscript>
</cffunction>

<cffunction name="$getFromCache" returntype="any" access="public" output="false">
	<cfargument name="key" type="string" required="true">
	<cfargument name="category" type="string" required="false" default="main">
	<cfscript>
		var loc = {};
		loc.returnValue = false;
		if (StructKeyExists(application.wheels.cache[arguments.category], arguments.key))
		{
			if (Now() > application.wheels.cache[arguments.category][arguments.key].expiresAt)
			{
				if (application.wheels.showDebugInformation)
					request.wheels.cacheCounts.culls = request.wheels.cacheCounts.culls + 1;
				$removeFromCache(key=arguments.key, category=arguments.category);
			}
			else
			{
				if (application.wheels.showDebugInformation)
					request.wheels.cacheCounts.hits = request.wheels.cacheCounts.hits + 1;
				if (IsSimpleValue(application.wheels.cache[arguments.category][arguments.key].value))
					loc.returnValue = application.wheels.cache[arguments.category][arguments.key].value;
				else
					loc.returnValue = Duplicate(application.wheels.cache[arguments.category][arguments.key].value);
			}
		}

		if (application.wheels.showDebugInformation && IsBoolean(loc.returnValue) && !loc.returnValue)
			request.wheels.cacheCounts.misses = request.wheels.cacheCounts.misses + 1;
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="$removeFromCache" returntype="void" access="public" output="false">
	<cfargument name="key" type="string" required="true">
	<cfargument name="category" type="string" required="false" default="main">
	<cfset StructDelete(application.wheels.cache[arguments.category], arguments.key)>
</cffunction>

<cffunction name="$cacheCount" returntype="numeric" access="public" output="false">
	<cfargument name="category" type="string" required="false" default="">
	<cfscript>
		var loc = {};
		if (Len(arguments.category))
		{
			loc.returnValue = StructCount(application.wheels.cache[arguments.category]);
		}
		else
		{
			loc.returnValue = 0;
			for (loc.key in application.wheels.cache)
				loc.returnValue = loc.returnValue + StructCount(application.wheels.cache[loc.key]);
		}
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<cffunction name="$clearCache" returntype="void" access="public" output="false">
	<cfargument name="category" type="string" required="false" default="">
	<cfscript>
		var loc = {};
		if (Len(arguments.category))
		{
			StructClear(application.wheels.cache[arguments.category]);
		}
		else
		{
			StructClear(application.wheels.cache);
		}
	</cfscript>
</cffunction>

<cffunction name="$createModelClass" returntype="any" access="public" output="false">
	<cfargument name="name" type="string" required="true">
	<cfscript>
		var loc = {};
		loc.fileName = capitalize(arguments.name);
		if (FileExists(ExpandPath("#application.wheels.modelPath#/#loc.fileName#.cfc")))
			application.wheels.existingModelFiles = ListAppend(application.wheels.existingModelFiles, arguments.name);
		else
			loc.fileName = "Model";
		application.wheels.models[arguments.name] = $createObjectFromRoot(path=application.wheels.modelComponentPath, fileName=loc.fileName, method="$initModelClass", name=arguments.name);
		loc.returnValue = application.wheels.models[arguments.name];
	</cfscript>
	<cfreturn loc.returnValue>
</cffunction>

<!---
Used to announce to the developer that a feature they are using will be removed at some point.
DOES NOT work in production mode.

To use call $deprecated() from within the method you want to deprecate. You may pass an optional
custom message if desired. The method will return a structure containing the message and information
about where the deprecation occurrs like the called method, line number, template name and shows the
code that called the deprcated method.

Example:

Original foo()
<cffunction name="foo" returntype="any" access="public" output="false">
	<cfargument name="baz" type="numeric" required="true">
	<cfreturn baz++>
</cffunction>

Should now call bar() instead and marking foo() as deprecated
<cffunction name="foo" returntype="any" access="public" output="false">
	<cfargument name="baz" type="numeric" required="true">
	<cfset $deprecated("Calling foo is now deprecated, use bar() instead.")>
	<cfreturn bar(argumentscollection=arguments)>
</cffunction>

<cffunction name="bar" returntype="any" access="public" output="false">
	<cfargument name="baz" type="numeric" required="true">
	<cfreturn ++baz>
</cffunction>
 --->
<cffunction name="$deprecated" returntype="struct" access="public" output="false">
	<!--- a message to display instead of the default one. --->
	<cfargument name="message" type="string" required="false" default="You are using deprecated behavior which will be removed from the next major or minor release.">
	<!--- should you announce the deprecation. only used when writing tests. --->
	<cfargument name="announce" type="boolean" required="false" default="true">
	<cfset var loc = {}>
	<cfset loc.ret = {}>
	<cfset loc.tagcontext = []>
	<cfif not application.wheels.showErrorInformation>
		<cfreturn loc.ret>
	</cfif>
	<!--- set return value --->
	<cfset loc.data = []>
	<cfset loc.ret = {message=arguments.message, line="", method="", template="", data=loc.data}>
	<!---
	create an exception so we can get the TagContext and display what file and line number the
	deprecated method is being called in
	 --->
	<cfset loc.exception = createObject("java","java.lang.Exception").init()>
	<cfif StructKeyExists(loc.exception, "tagcontext")>
		<cfset loc.tagcontext = loc.exception.tagcontext>
	</cfif>
	<!---
	TagContext is an array. The first element of the array will always be the context for this
	method announcing the deprecation. The second element will be the deprecated function that
	is being called. We need to look at the third element of the array to get the method that
	is calling the method marked for deprecation.
	 --->
	<cfif isArray(loc.tagcontext) and arraylen(loc.tagcontext) gte 3 and isStruct(loc.tagcontext[3])>
		<!--- grab and parse the information from the tagcontext. --->
		<cfset loc.context = loc.tagcontext[3]>
		<!--- the line number --->
		<cfset loc.ret.line = loc.context.line>
		<!--- the deprecated method that was called --->
		<cfset loc.ret.method = rereplacenocase(loc.context.raw_trace, ".*\$func([^\.]*)\..*", "\1")>
		<!--- the user template where the method called occurred --->
		<cfset loc.ret.template = loc.context.template>
		<!--- try to get the code --->
 		<cfif len(loc.ret.template) and FileExists(loc.ret.template)>
			<!--- grab a one line radius from where the deprecation occurred. --->
			<cfset loc.startAt = loc.ret.line - 1>
			<cfif loc.startAt lte 0>
				<cfset loc.startAt = loc.ret.line>
			</cfif>
			<cfset loc.stopAt = loc.ret.line + 1>
			<cfset loc.counter = 1>
			<cfloop file="#loc.ret.template#" index="loc.i">
				<cfif loc.counter gte loc.startAt and loc.counter lte loc.stopAt>
					<cfset arrayappend(loc.ret.data, loc.i)>
				</cfif>
				<cfif loc.counter gt loc.stopAt>
					<cfbreak>
				</cfif>
				<cfset loc.counter++>
			</cfloop>
		</cfif>
		<!--- change template name from full to relative path. --->
		<cfset loc.ret.template = listchangedelims(removechars(loc.ret.template, 1, len(expandpath(application.wheels.webpath))), "/", "\/")>
	</cfif>
	<!--- append --->
	<cfif arguments.announce>
		<cfset arrayappend(request.wheels.deprecation, loc.ret)>
	</cfif>
	<cfreturn loc.ret>
</cffunction>

<cffunction name="$loadRoutes" returntype="void" access="public" output="false">
	<cfscript>
		// clear out the route info
		ArrayClear(application.wheels.routes);
		StructClear(application.wheels.namedRoutePositions);

		// load developer routes first
		$include(template="#application.wheels.configPath#/routes.cfm");

		// add the wheels default routes at the end if requested
		if (application.wheels.loadDefaultRoutes)
			addDefaultRoutes();

		// set lookup info for the named routes
		$setNamedRoutePositions();
		</cfscript>
</cffunction>

<cffunction name="$setNamedRoutePositions" returntype="void" access="public" output="false">
	<cfscript>
		var loc = {};
		loc.iEnd = ArrayLen(application.wheels.routes);
		for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
		{
			loc.route = application.wheels.routes[loc.i];
			if (StructKeyExists(loc.route, "name") && len(loc.route.name))
			{
				if (!StructKeyExists(application.wheels.namedRoutePositions, loc.route.name))
					application.wheels.namedRoutePositions[loc.route.name] = "";
				application.wheels.namedRoutePositions[loc.route.name] = ListAppend(application.wheels.namedRoutePositions[loc.route.name], loc.i);
			}
		}
		</cfscript>
</cffunction>

<cffunction name="$clearModelInitializationCache">
	<cfset StructClear(application.wheels.models)>
</cffunction>

<cffunction name="$clearControllerInitializationCache">
	<cfset StructClear(application.wheels.controllers)>
</cffunction>

<cffunction name="$loadPlugins" returntype="void" access="public" output="false">
	<cfscript>
	var loc = {};
	application.wheels.plugins = {};
	application.wheels.incompatiblePlugins = "";
	application.wheels.mixableComponents = "application,dispatch,controller,model,microsoftsqlserver,mysql,oracle,postgresql,sqlite";
	application.wheels.mixins = {};
	application.wheels.dependantPlugins = "";
	loc.pluginFolder = GetDirectoryFromPath(GetBaseTemplatePath()) & "plugins";

	// get a list of plugin files and folders
	loc.pluginFolders = $directory(directory=loc.pluginFolder, type="dir");
	loc.pluginFiles = $directory(directory=loc.pluginFolder, filter="*.zip", type="file", sort="name DESC");

	// delete plugin directories if no corresponding plugin zip file exists
	if (application.wheels.deletePluginDirectories)
	{
		loc.iEnd = loc.pluginFolders.recordCount;
		for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
		{
			loc.name = loc.pluginFolders["name"][loc.i];
			loc.directory = loc.pluginFolders["directory"][loc.i];
			if (Left(loc.name, 1) != "." && !ListContainsNoCase(ValueList(loc.pluginFiles.name), loc.name & "-"))
			{
				loc.directory = loc.directory & "/" & loc.name;
				$directory(action="delete", directory=loc.directory, recurse=true);
			}
		}
	}

	// create directory and unzip code for the most recent version of each plugin
	if (loc.pluginFiles.recordCount)
	{
		loc.iEnd = loc.pluginFiles.recordCount;
		for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
		{
			loc.name = loc.pluginFiles["name"][loc.i];
			loc.pluginName = ListFirst(loc.name, "-");
			if (!StructKeyExists(application.wheels.plugins, loc.pluginName))
			{
				loc.pluginVersion = Replace(ListLast(loc.name, "-"), ".zip", "", "one");
				loc.thisPluginFile = loc.pluginFolder & "/" & loc.name;
				loc.thisPluginFolder = loc.pluginFolder & "/" & LCase(loc.pluginName);
				if (!DirectoryExists(loc.thisPluginFolder))
					$directory(action="create", directory=loc.thisPluginFolder);
				$zip(action="unzip", destination=loc.thisPluginFolder, file=loc.thisPluginFile, overwrite=application.wheels.overwritePlugins);
				loc.fileName = LCase(loc.pluginName) & "." & loc.pluginName;
				loc.plugin = $createObjectFromRoot(path=application.wheels.pluginComponentPath, fileName=loc.fileName, method="init");
				loc.plugin.pluginVersion = loc.pluginVersion;
				if (!StructKeyExists(loc.plugin, "version") || ListFind(loc.plugin.version, SpanExcluding(application.wheels.version, " ")) || application.wheels.loadIncompatiblePlugins)
				{
					application.wheels.plugins[loc.pluginName] = loc.plugin;
					if (StructKeyExists(loc.plugin, "version") && !ListFind(loc.plugin.version, SpanExcluding(application.wheels.version, " ")))
						application.wheels.incompatiblePlugins = ListAppend(application.wheels.incompatiblePlugins, loc.pluginName);
				}
			}
		}
		// store plugin injection information in application scope so we don't have to run this code on each injection
		loc.iEnd = ListLen(application.wheels.mixableComponents);
		for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
		{
			application.wheels.mixins[ListGetAt(application.wheels.mixableComponents, loc.i)] = {};
		}
		loc.iList = StructKeyList(application.wheels.plugins);
		loc.iEnd = ListLen(loc.iList);
		for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
		{
			loc.iItem = ListGetAt(loc.iList, loc.i);
			loc.pluginMeta = GetMetaData(application.wheels.plugins[loc.iItem]); // grab meta data of the plugin
			if (!StructKeyExists(loc.pluginMeta, "environment") || ListFindNoCase(loc.pluginMeta.environment, application.wheels.environment))
			{
				loc.pluginMixins = "global"; // by default and for backwards compatibility, we inject all methods into all objects
				if (StructKeyExists(loc.pluginMeta, "mixin"))
					loc.pluginMixins = loc.pluginMeta["mixin"]; // if the component has a default mixin value, assign that value
				// loop through all plugin methods and enter injection info accordingly (based on the mixin value on the method or the default one set on the entire component)
				loc.jList = StructKeyList(application.wheels.plugins[loc.iItem]);
				loc.jEnd = ListLen(loc.jList);
				for (loc.j=1; loc.j <= loc.jEnd; loc.j++)
				{
					loc.jItem = ListGetAt(loc.jList, loc.j);
					if (IsCustomFunction(application.wheels.plugins[loc.iItem][loc.jItem]) && loc.jItem != "init")
					{
						loc.methodMeta = GetMetaData(application.wheels.plugins[loc.iItem][loc.jItem]);
						loc.methodMixins = loc.pluginMixins;
						if (StructKeyExists(loc.methodMeta, "mixin"))
							loc.methodMixins = loc.methodMeta["mixin"];
						// mixin all methods except those marked as none
						if (loc.methodMixins != "none")
						{
							loc.kEnd = ListLen(application.wheels.mixableComponents);
							for (loc.k=1; loc.k <= loc.kEnd; loc.k++)
							{
								loc.kItem = ListGetAt(application.wheels.mixableComponents, loc.k);
								if (loc.methodMixins == "global" || ListFindNoCase(loc.methodMixins, loc.kItem))
									application.wheels.mixins[loc.kItem][loc.jItem] = application.wheels.plugins[loc.iItem][loc.jItem];
							}
						}
					}
				}
			}
		}
		// look for plugins that are incompatible with each other
		loc.addedFunctions = "";
		for (loc.key in application.wheels.plugins)
		{
			for (loc.keyTwo in application.wheels.plugins[loc.key])
			{
				if (!ListFindNoCase("init,version,pluginVersion", loc.keyTwo))
				{
					if (ListFindNoCase(loc.addedFunctions, loc.keyTwo))
						$throw(type="Wheels.IncompatiblePlugin", message="#loc.key# is incompatible with a previously installed plugin.", extendedInfo="Make sure none of the plugins you have installed override the same Wheels functions.");
					else
						loc.addedFunctions = ListAppend(loc.addedFunctions, loc.keyTwo);
				}
			}
		}
		// look for plugins that depend on other plugins that are not installed
		for (loc.key in application.wheels.plugins)
		{
			loc.pluginInfo = GetMetaData(application.wheels.plugins[loc.key]);
			if (StructKeyExists(loc.pluginInfo, "dependency"))
			{
				loc.iEnd = ListLen(loc.pluginInfo.dependency);
				for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
				{
					loc.iItem = ListGetAt(loc.pluginInfo.dependency, loc.i);
					if (!StructKeyExists(application.wheels.plugins, loc.iItem))
						application.wheels.dependantPlugins = ListAppend(application.wheels.dependantPlugins, Reverse(SpanExcluding(Reverse(loc.pluginInfo.name), ".")) & "|" & loc.iItem);
				}
			}
		}
	}

	// allow developers to inject plugins into the application variables scope
	if (!StructIsEmpty(application.wheels.mixins))
		$include(template="wheels/plugins/injection.cfm");
	</cfscript>
</cffunction>