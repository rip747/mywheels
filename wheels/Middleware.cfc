<cfcomponent output="false">

	<cfset stacks = {}>


	<cffunction name="init">
		<cfargument name="stackList" type="string" default="self">
		<cfset var loc = {}>
		<cfloop list="#arguments.stackList#" index="loc.i">
			<cfset stacks[loc.i] = []>
		</cfloop>
		<cfreturn this>
	</cffunction>


	<cffunction name="inject" access="public" returntype="void" output="false">
		<cfargument name="index" type="any" required="true">
		<cfargument name="middleware" type="string" required="true">
		<cfargument name="stack" type="string" required="false" default="self">
		<cfset var loc = {}>
		<cfif NOT IsNumeric(arguments.index)>
			<cfset arguments.index = position(arguments.index, arguments.stack)>
		</cfif>
		<cfset arguments.middleware = lcase(arguments.middleware)>
		<cfif arguments.index eq 0 OR arguments.index gt ArrayLen(stacks[arguments.stack])>
			<cfset ArrayAppend(stacks[arguments.stack], arguments.middleware)>
		<cfelse>
			<cfset ArrayInsertAt(stacks[arguments.stack], arguments.index, arguments.middleware)>
		</cfif>
	</cffunction>


	<cffunction name="inject_before" access="public" returntype="void" output="false">
		<cfset inject(argumentCollection=arguments)>
	</cffunction>


	<cffunction name="inject_after" access="public" returntype="void" output="false">
		<cfargument name="index" type="any" required="true">
		<cfargument name="middleware" type="string" required="true">
		<cfargument name="stack" type="string" required="false" default="self">
		<cfset arguments.index = position(arguments.index, arguments.stack)>
		<cfif arguments.index eq 0>
			<cfset StackMiddlewareNotFound(argumentCollection=arguments)>
		</cfif>
		<cfset arguments.index++>
		<cfset inject(argumentCollection=arguments)>
	</cffunction>


	<cffunction name="swap" access="public" returntype="void" output="false">
		<cfargument name="target" type="any" required="true">
		<cfargument name="middleware" type="string" required="true">
		<cfargument name="stack" type="string" required="false" default="self">
		<cfset inject(arguments.target, arguments.middleware, arguments.stack)>
		<cfset ArrayDeleteAt(stacks[arguments.stack], position(arguments.target, arguments.stack))>
	</cffunction>


	<cffunction name="position" access="public" returntype="numeric" output="false">
		<cfargument name="middleware" type="string" required="true">
		<cfargument name="stack" type="string" required="false" default="self">
		<cfreturn stacks[arguments.stack].indexOf(lcase(arguments.middleware)) + 1>
	</cffunction>


	<cffunction name="inspect" access="public" returntype="any" output="false">
		<cfargument name="stack" type="string" required="false">
		<cfif StructKeyExists(arguments, "stack")>
			<cfreturn stacks[arguments.stack]>
		</cfif>
		<cfreturn stacks>
	</cffunction>


	<cffunction name="StackMiddlewareNotFound" access="private" returntype="void" output="false">
		<cfthrow type="Stack.MiddlewareNotFound" message="the middlware does not exist in the stack: #arguments.stack#">
	</cffunction>

</cfcomponent>