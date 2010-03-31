<cfcomponent extends="wheelsMapping.test">

	<cfinclude template="/wheelsMapping/global/functions.cfm">

	<cfset controller = $controller(name="dummy").$createControllerObject({controller="dummy",action="dummy"})>

	<cffunction name="setup">
		<cfset oldCGIScope = request.cgi>
	</cffunction>

	<cffunction name="test_isGet_valid">
		<cfset request.cgi.request_method = "get">
		<cfset assert("controller.isGet() eq true")>
	</cffunction>
	
	<cffunction name="test_isGet_invalid">
		<cfset request.cgi.request_method = "">
		<cfset assert("controller.isGet() eq false")>
	</cffunction>

	<cffunction name="teardown">
		<cfset request.cgi = oldCGIScope>
	</cffunction>

</cfcomponent>