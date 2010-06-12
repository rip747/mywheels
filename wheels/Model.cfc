<!--- This file is only needed to get tests to work --->
<cfcomponent output="false" extends="ModelBase">
	<cfset structappend(this, application.wheels._classes.model)>
	<cfset structappend(variables, this)>
</cfcomponent>