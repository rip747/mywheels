<cfcomponent extends="wheelsMapping.test">

	<cfinclude template="setupAndTeardown.cfm">

	<cfset params = {controller="test", action="test"}>
	<cfset controller = $controller(name="test").$createControllerObject(params)>
	
	<cffunction name="test_rendering_without_layout">
		<cfset controller.renderPage(layout=false)>
		<cfset assert("controller.response() IS 'view template content'")>
	</cffunction>

	<cffunction name="test_rendering_with_default_layout_in_controller_folder">
		<cfset tempFile = Replace(Replace(GetCurrentTemplatePath(), "\", "/", "all"), "controller/rendering/layouts.cfc", "_assets/views/test/layout.cfm")>
		<cffile action="write" output="<cfoutput>start:controllerlayout##includeContent()##end:controllerlayout</cfoutput>" file="#tempFile#">
		<cfset application.wheels.existingLayoutFiles = "test">
		<cfset controller.renderPage()>
		<cfset loc.r = controller.response()>
		<cfset assert("loc.r Contains 'view template content' AND loc.r Contains 'start:controllerlayout' AND loc.r Contains 'end:controllerlayout'")>
		<cfset application.wheels.existingLayoutFiles = "">
		<cffile action="delete" file="#tempFile#">
	</cffunction>

	<cffunction name="test_rendering_with_default_layout_in_root">
		<cfset controller.renderPage()>
		<cfset loc.r = controller.response()>
		<cfset assert("loc.r Contains 'view template content' AND loc.r Contains 'start:defaultlayout' AND loc.r Contains 'end:defaultlayout'")>
	</cffunction>

	<cffunction name="test_rendering_with_specific_layout">
		<cfset controller.renderPage(layout="specificLayout")>
		<cfset loc.r = controller.response()>
		<cfset assert("loc.r Contains 'view template content' AND loc.r Contains 'start:specificlayout' AND loc.r Contains 'end:specificlayout'")>
	</cffunction>

	<cffunction name="test_removing_cfm_file_extension_when_supplied">
		<cfset controller.renderPage(layout="specificLayout.cfm")>
		<cfset loc.r = controller.response()>
		<cfset assert("loc.r Contains 'view template content' AND loc.r Contains 'start:specificlayout' AND loc.r Contains 'end:specificlayout'")>
	</cffunction>

	<cffunction name="test_rendering_with_specific_layout_in_root">
		<cfset controller.renderPage(layout="/rootLayout")>
		<cfset loc.r = controller.response()>
		<cfset assert("loc.r Contains 'view template content' AND loc.r Contains 'start:rootlayout' AND loc.r Contains 'end:rootlayout'")>
	</cffunction>

	<cffunction name="test_rendering_with_specific_layout_in_sub_folder">
		<cfset controller.renderPage(layout="sub/layout")>
		<cfset loc.r = controller.response()>
		<cfset assert("loc.r Contains 'view template content' AND loc.r Contains 'start:sublayout' AND loc.r Contains 'end:sublayout'")>
	</cffunction>

	<cffunction name="test_rendering_with_specific_layout_from_folder_path">
		<cfset controller.renderPage(layout="/shared/layout")>
		<cfset loc.r = controller.response()>
		<cfset assert("loc.r Contains 'view template content' AND loc.r Contains 'start:sharedlayout' AND loc.r Contains 'end:sharedlayout'")>
	</cffunction>

	<cffunction name="test_view_variable_should_be_available_in_layout_file">
		<cfset controller.$callAction(action="test")>
		<cfset controller.renderPage()>
		<cfset loc.r = controller.response()>
		<cfset assert("loc.r Contains 'view template content' AND loc.r Contains 'variableForLayoutContent' AND loc.r Contains 'start:defaultlayout' AND loc.r Contains 'end:defaultlayout'")>
	</cffunction>

	<cffunction name="test_rendering_partial_with_layout">
		<cfset controller.renderPartial(partial="partialTemplate", layout="partialLayout")>
		<cfset loc.r = controller.response()>
		<cfset assert("loc.r Contains 'partial template content' AND loc.r Contains 'start:partiallayout' AND loc.r Contains 'end:partiallayout'")>
	</cffunction>

	<cffunction name="test_rendering_partial_with_specific_layout_in_root">
		<cfset controller.renderPartial(partial="partialTemplate", layout="/partialRootLayout")>
		<cfset loc.r = controller.response()>
		<cfset assert("loc.r Contains 'partial template content' AND loc.r Contains 'start:partialrootlayout' AND loc.r Contains 'end:partialrootlayout'")>
	</cffunction>

</cfcomponent>