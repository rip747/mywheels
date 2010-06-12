<cfcomponent output="false">
	<cfset structappend(this, application.wheels._classes.modelbase)>
	<cfset structappend(variables, this)>
	<cfset structappend(super, this)>
</cfcomponent>