<cfcomponent output="false" mixin="controller,model,dispatch,global">

		<cffunction name="init">
		<cfset this.version = "1.1.8">
		<cfreturn this>
	</cffunction>
	
	<cffunction name="CSVToQuery" access="public" returntype="query" output="false" hint="Converts the given CSV string to a query.">
 
		<cfargument name="CSV" type="string" required="true" hint="This is the CSV string that will be manipulated." />
		<cfargument name="Delimiter" type="string" required="false" default="," hint="This is the delimiter that will separate the fields within the CSV value." />
		<cfargument name="Qualifier" type="string" required="false" default="""" hint="This is the qualifier that will wrap around fields that have special characters embeded." />
		 
		<cfset var LOCAL = StructNew() />
		<cfset ARGUMENTS.Delimiter = Left( ARGUMENTS.Delimiter, 1 ) />
		<cfif Len( ARGUMENTS.Qualifier )>
			<cfset ARGUMENTS.Qualifier = Left( ARGUMENTS.Qualifier, 1 ) />
		</cfif>
		<cfset LOCAL.LineDelimiter = Chr( 10 ) />
		<cfset ARGUMENTS.CSV = ARGUMENTS.CSV.ReplaceAll("\r?\n", LOCAL.LineDelimiter) />
		<cfset LOCAL.Delimiters = ARGUMENTS.CSV.ReplaceAll("[^\#ARGUMENTS.Delimiter#\#LOCAL.LineDelimiter#]+","").ToCharArray() />
		<cfset ARGUMENTS.CSV = (" " & ARGUMENTS.CSV) />
		<cfset ARGUMENTS.CSV = ARGUMENTS.CSV.ReplaceAll("([\#ARGUMENTS.Delimiter#\#LOCAL.LineDelimiter#]{1})","$1 ") />
		<cfset LOCAL.Tokens = ARGUMENTS.CSV.Split("[\#ARGUMENTS.Delimiter#\#LOCAL.LineDelimiter#]{1}") />
		<cfset LOCAL.Rows = ArrayNew( 1 ) />
		<cfset ArrayAppend(LOCAL.Rows,	ArrayNew( 1 )) />
		<cfset LOCAL.RowIndex = 1 />
		<cfset LOCAL.IsInValue = false />
		<cfloop index="LOCAL.TokenIndex" from="1" to="#ArrayLen( LOCAL.Tokens )#" step="1">
			<cfset LOCAL.FieldIndex = ArrayLen(LOCAL.Rows[ LOCAL.RowIndex ]) />
			<cfset LOCAL.Token = LOCAL.Tokens[ LOCAL.TokenIndex ].ReplaceFirst("^.{1}","") />
			<cfif Len( ARGUMENTS.Qualifier )>
				<cfif LOCAL.IsInValue>
					<cfset LOCAL.Token = LOCAL.Token.ReplaceAll("\#ARGUMENTS.Qualifier#{2}","{QUALIFIER}") />
					<cfset LOCAL.Rows[ LOCAL.RowIndex ][ LOCAL.FieldIndex ] = (LOCAL.Rows[ LOCAL.RowIndex ][ LOCAL.FieldIndex ] & LOCAL.Delimiters[ LOCAL.TokenIndex - 1 ] & LOCAL.Token ) />
					<cfif (Right( LOCAL.Token, 1 ) EQ ARGUMENTS.Qualifier)>
						<cfset LOCAL.Rows[ LOCAL.RowIndex ][ LOCAL.FieldIndex ] = LOCAL.Rows[ LOCAL.RowIndex ][ LOCAL.FieldIndex ].ReplaceFirst( ".{1}$", "" ) />
						<cfset LOCAL.IsInValue = false />
					</cfif>
				<cfelse>
					<cfif (Left( LOCAL.Token, 1 ) EQ ARGUMENTS.Qualifier)>
						<cfset LOCAL.Token = LOCAL.Token.ReplaceFirst("^.{1}","") />
						<cfset LOCAL.Token = LOCAL.Token.ReplaceAll("\#ARGUMENTS.Qualifier#{2}","{QUALIFIER}") />
						<cfif (Right( LOCAL.Token, 1 ) EQ ARGUMENTS.Qualifier)>
							<cfset ArrayAppend(LOCAL.Rows[ LOCAL.RowIndex ],LOCAL.Token.ReplaceFirst(".{1}$","")) />
						<cfelse>
							<cfset LOCAL.IsInValue = true />
							<cfset ArrayAppend(LOCAL.Rows[ LOCAL.RowIndex ],LOCAL.Token) />
						</cfif>
					<cfelse>
						<cfset ArrayAppend(LOCAL.Rows[ LOCAL.RowIndex ],LOCAL.Token) />
					</cfif>
				</cfif>
				<cfset LOCAL.Rows[ LOCAL.RowIndex ][ ArrayLen( LOCAL.Rows[ LOCAL.RowIndex ] ) ] = Replace(LOCAL.Rows[ LOCAL.RowIndex ][ ArrayLen( LOCAL.Rows[ LOCAL.RowIndex ] ) ],"{QUALIFIER}",ARGUMENTS.Qualifier,"ALL") />
			<cfelse>
				<cfset ArrayAppend(LOCAL.Rows[ LOCAL.RowIndex ],LOCAL.Token) />
			</cfif>
			<cfif ((NOT LOCAL.IsInValue) AND (LOCAL.TokenIndex LT ArrayLen( LOCAL.Tokens )) AND (LOCAL.Delimiters[ LOCAL.TokenIndex ] EQ LOCAL.LineDelimiter))>
				<cfset ArrayAppend(LOCAL.Rows,ArrayNew( 1 )) />
				<cfset LOCAL.RowIndex = (LOCAL.RowIndex + 1) />
			</cfif>
		</cfloop>
		<cfset LOCAL.MaxFieldCount = 0 />
		<cfset LOCAL.EmptyArray = ArrayNew( 1 ) />
		<cfloop index="LOCAL.RowIndex" from="1" to="#ArrayLen( LOCAL.Rows )#" step="1">
			<cfset LOCAL.MaxFieldCount = Max(LOCAL.MaxFieldCount,ArrayLen(LOCAL.Rows[ LOCAL.RowIndex ])) />
			<cfset ArrayAppend(LOCAL.EmptyArray,"") />
		</cfloop>
		<cfset LOCAL.Query = QueryNew( "" ) />
		<cfloop index="LOCAL.FieldIndex" from="1" to="#LOCAL.MaxFieldCount#" step="1">
			<cfset QueryAddColumn(LOCAL.Query, "COLUMN_#LOCAL.FieldIndex#", "CF_SQL_VARCHAR", LOCAL.EmptyArray ) />
		</cfloop>
		<cfloop index="LOCAL.RowIndex" from="1" to="#ArrayLen( LOCAL.Rows )#" step="1">
			<cfloop index="LOCAL.FieldIndex" from="1" to="#ArrayLen( LOCAL.Rows[ LOCAL.RowIndex ] )#" step="1">
				<cfset LOCAL.Query[ "COLUMN_#LOCAL.FieldIndex#" ][ LOCAL.RowIndex ] = JavaCast("string",LOCAL.Rows[ LOCAL.RowIndex ][ LOCAL.FieldIndex ]) />
			</cfloop>
		</cfloop>

		<cfreturn LOCAL.Query />
	 
	</cffunction>


</cfcomponent>