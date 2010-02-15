<cfcomponent extends="wheelsmapping.test">

	<cfset global.middleware = createobject("component", "wheelsmapping.middleware")>

	<cffunction name="test_default_stack">
		<cfset loc.m = loc.middleware.init()>
		<cfset loc.e = loc.m.inspect()>
		<cfset assert('structkeyexists(loc.e, "self")')>
		<cfset assert('arrayisempty(loc.e.self)')>
	</cffunction>

	<cffunction name="test_defined_stacks">
		<cfset loc.m = loc.middleware.init("stack1,stack2")>
		<cfset loc.e = loc.m.inspect()>
		<cfset assert('structkeyexists(loc.e, "stack1")')>
		<cfset assert('structkeyexists(loc.e, "stack2")')>
		<cfset assert('arrayisempty(loc.e.stack1)')>
		<cfset assert('arrayisempty(loc.e.stack2)')>
	</cffunction>

	<cffunction name="test_inject">
		<cfset loc.m = loc.middleware.init("stack1")>
		<cfset loc.m.inject(4, "pos1","stack1")>
		<cfset loc.e = loc.m.inspect()>
		<cfset assert('arrayLen(loc.e.stack1) eq 1')>
		<cfset assert('loc.e.stack1[1] eq "pos1"')>
	</cffunction>

	<cffunction name="test_raised_stack_error">
		<cfset loc.m = loc.middleware.init("stack1")>
		<cfset loc.e = raised('loc.m.inject(1, "pos1","stacka")')>
		<cfset assert('loc.e eq "Expression"')>
	</cffunction>

	<cffunction name="test_inject_before_middleware_exists">
		<cfset loc.m = loc.middleware.init("stack1")>
		<cfset loc.m.inject(1, "pos1","stack1")>
		<cfset loc.m.inject(2, "pos2","stack1")>
		<cfset loc.m.inject_before("pos2", "pos3","stack1")>
		<cfset loc.e = loc.m.inspect()>
		<cfset assert('loc.e.stack1[1] eq "pos1"')>
		<cfset assert('loc.e.stack1[2] eq "pos3"')>
		<cfset assert('loc.e.stack1[3] eq "pos2"')>
	</cffunction>

	<cffunction name="test_inject_before_middleware_not_exists">
		<cfset loc.m = loc.middleware.init("stack1")>
		<cfset loc.m.inject(1, "pos1","stack1")>
		<cfset loc.m.inject(2, "pos2","stack1")>
		<cfset loc.m.inject_before("pos4", "pos3","stack1")>
		<cfset loc.e = loc.m.inspect()>
		<cfset assert('loc.e.stack1[1] eq "pos1"')>
		<cfset assert('loc.e.stack1[2] eq "pos2"')>
		<cfset assert('loc.e.stack1[3] eq "pos3"')>
	</cffunction>

	<cffunction name="test_inject_after_middleware_exists">
		<cfset loc.m = loc.middleware.init("stack1")>
		<cfset loc.m.inject(1, "pos1","stack1")>
		<cfset loc.m.inject(2, "pos2","stack1")>
		<cfset loc.m.inject_after("pos1", "pos3","stack1")>
		<cfset loc.e = loc.m.inspect()>
		<cfset assert('loc.e.stack1[1] eq "pos1"')>
		<cfset assert('loc.e.stack1[2] eq "pos3"')>
		<cfset assert('loc.e.stack1[3] eq "pos2"')>
	</cffunction>

	<cffunction name="test_inject_after_middleware_not_exists">
		<cfset loc.m = loc.middleware.init("stack1")>
		<cfset loc.m.inject(1, "pos1","stack1")>
		<cfset loc.m.inject(2, "pos2","stack1")>
		<cfset loc.e = raised('loc.m.inject_after("pos4", "pos3","stack1")')>
		<cfset assert('loc.e eq "Stack.MiddlewareNotFound"')>
	</cffunction>

	<cffunction name="test_swap">
		<cfset loc.m = loc.middleware.init("stack1")>
		<cfset loc.m.inject(1, "pos1","stack1")>
		<cfset loc.m.inject(2, "pos2","stack1")>
		<cfset loc.m.swap("pos2", "pos3","stack1")>
		<cfset loc.e = loc.m.inspect()>
		<cfset assert('arrayLen(loc.e.stack1) eq 2')>
		<cfset assert('loc.e.stack1[1] eq "pos1"')>
		<cfset assert('loc.e.stack1[2] eq "pos3"')>
	</cffunction>

</cfcomponent>