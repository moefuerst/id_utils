# This file contains the configuration for Credo
%{
  #
  # You can have as many configs as you like in the `configs:` field.
  configs: [
    %{
      #
      # Run any config using `mix credo -C <name>`. If no config name is given
      # "default" is used.
      #
      name: "default",
      #
      # These are the files included in the analysis:
      files: %{
        #
        # You can give explicit globs or simply directories.
        # In the latter case `**/*.{ex,exs}` will be used.
        #
        included: [
          "lib/",
          "src/",
          "test/",
          "web/",
          "apps/*/lib/",
          "apps/*/src/",
          "apps/*/test/",
          "apps/*/web/"
        ],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/"]
      },
      #
      # Load and configure plugins here:
      #
      plugins: [],
      #
      # If you create your own checks, you must specify the source files for
      # them here, so they can be loaded by Credo before running the analysis.
      #
      requires: [],
      #
      # If you want to enforce a style guide and need a more traditional linting
      # experience, you can change `strict` to `true` below:
      #
      strict: false,
      #
      # To modify the timeout for parsing files, change this value:
      #
      parse_timeout: 5000,
      #
      # If you want to use uncolored output by default, you can change `color`
      # to `false` below:
      #
      color: true,
      #
      # You can customize the parameters of any check by adding a second element
      # to the tuple.
      #
      # To disable a check put `false` as second element:
      #
      #     {Credo.Check.Design.DuplicatedCode, false}
      #
      checks: %{
        enabled: [
          #
          ## Consistency Checks
          #
          {Credo.Check.Consistency.ExceptionNames, []},
          {Credo.Check.Consistency.LineEndings, []},
          {Credo.Check.Consistency.ParameterPatternMatching, []},
          {Credo.Check.Consistency.SpaceAroundOperators, []},
          {Credo.Check.Consistency.SpaceInParentheses, []},
          {Credo.Check.Consistency.TabsOrSpaces, []},
          {Credo.Check.Consistency.MultiAliasImportRequireUse, []},

          #
          ## Design Checks
          #
          # You can customize the priority of any check
          # Priority values are: `low, normal, high, higher`
          #
          {Credo.Check.Design.AliasUsage, [if_nested_deeper_than: 2, if_called_more_often_than: 1]},
          {Credo.Check.Design.TagFIXME, []},
          {Credo.Check.Design.TagTODO, [exit_status: 0]},
          {Credo.Check.Design.SkipTestWithoutComment, []},

          #
          ## Readability Checks
          #
          {Credo.Check.Readability.AliasOrder, []},
          {Credo.Check.Readability.BlockPipe, [priority: :low, exit_status: 0]},
          {Credo.Check.Readability.FunctionNames, []},
          {Credo.Check.Readability.LargeNumbers, []},
          {Credo.Check.Readability.MaxLineLength, [priority: :low, max_length: 110]},
          {Credo.Check.Readability.ModuleAttributeNames, []},
          {Credo.Check.Readability.ModuleDoc, []},
          {Credo.Check.Readability.ModuleNames, []},
          {Credo.Check.Readability.MultiAlias, []},
          {Credo.Check.Readability.OneArityFunctionInPipe, []},
          {Credo.Check.Readability.OnePipePerLine, []},
          {Credo.Check.Readability.ParenthesesInCondition, []},
          {Credo.Check.Readability.ParenthesesOnZeroArityDefs, []},
          {Credo.Check.Readability.PipeIntoAnonymousFunctions, []},
          {Credo.Check.Readability.PredicateFunctionNames, []},
          {Credo.Check.Readability.PreferImplicitTry, []},
          {Credo.Check.Readability.RedundantBlankLines, []},
          {Credo.Check.Readability.Semicolons, []},
          {Credo.Check.Readability.SinglePipe, []},
          {Credo.Check.Readability.SpaceAfterCommas, []},
          {Credo.Check.Readability.StrictModuleLayout,
           order: [
             :shortdoc,
             :moduledoc,
             :behaviour,
             :use,
             :import,
             :alias,
             :require,
             :module_attribute,
             :defstruct,
             :type,
             :typep,
             :opaque,
             :callback,
             :macrocallback,
             :optional_callbacks
           ]},
          {Credo.Check.Readability.StringSigils, []},
          {Credo.Check.Readability.TrailingBlankLine, []},
          {Credo.Check.Readability.TrailingWhiteSpace, []},
          {Credo.Check.Readability.UnnecessaryAliasExpansion, []},
          {Credo.Check.Readability.VariableNames, []},
          {Credo.Check.Readability.WithSingleClause, []},

          #
          ## Refactoring Opportunities
          #
          {Credo.Check.Refactor.Apply, []},
          {Credo.Check.Refactor.AppendSingleItem, []},
          {Credo.Check.Refactor.CaseTrivialMatches, []},
          {Credo.Check.Refactor.CondStatements, []},
          {Credo.Check.Refactor.CyclomaticComplexity, []},
          {Credo.Check.Refactor.DoubleBooleanNegation, []},
          {Credo.Check.Refactor.FilterCount, []},
          {Credo.Check.Refactor.FilterFilter, []},
          {Credo.Check.Refactor.FunctionArity, []},
          {Credo.Check.Refactor.LongQuoteBlocks, []},
          {Credo.Check.Refactor.MapJoin, []},
          {Credo.Check.Refactor.MapMap, []},
          {Credo.Check.Refactor.MatchInCondition, []},
          {Credo.Check.Refactor.NegatedConditionsInUnless, []},
          {Credo.Check.Refactor.NegatedConditionsWithElse, []},
          {Credo.Check.Refactor.Nesting, []},
          {Credo.Check.Refactor.PipeChainStart, []},
          {Credo.Check.Refactor.RedundantWithClauseResult, []},
          {Credo.Check.Refactor.RejectReject, []},
          {Credo.Check.Refactor.UnlessWithElse, []},
          {Credo.Check.Refactor.UtcNowTruncate, []},
          {Credo.Check.Refactor.WithClauses, []},

          #
          ## Warnings
          #
          {Credo.Check.Warning.ApplicationConfigInModuleAttribute, []},
          {Credo.Check.Warning.BoolOperationOnSameValues, []},
          {Credo.Check.Warning.Dbg, []},
          {Credo.Check.Warning.ExpensiveEmptyEnumCheck, []},
          {Credo.Check.Warning.IExPry, []},
          {Credo.Check.Warning.IoInspect, []},
          {Credo.Check.Warning.MissedMetadataKeyInLoggerConfig, []},
          {Credo.Check.Warning.OperationOnSameValues, []},
          {Credo.Check.Warning.OperationWithConstantResult, []},
          {Credo.Check.Warning.RaiseInsideRescue, []},
          {Credo.Check.Warning.SpecWithStruct, []},
          {Credo.Check.Warning.StructFieldAmount, []},
          {Credo.Check.Warning.UnsafeExec, []},
          {Credo.Check.Warning.UnsafeToAtom, []},
          {Credo.Check.Warning.UnusedEnumOperation, []},
          {Credo.Check.Warning.UnusedFileOperation, []},
          {Credo.Check.Warning.UnusedKeywordOperation, []},
          {Credo.Check.Warning.UnusedListOperation, []},
          {Credo.Check.Warning.UnusedMapOperation, []},
          {Credo.Check.Warning.UnusedPathOperation, []},
          {Credo.Check.Warning.UnusedRegexOperation, []},
          {Credo.Check.Warning.UnusedStringOperation, []},
          {Credo.Check.Warning.UnusedTupleOperation, []},
          {Credo.Check.Warning.WrongTestFilename, []},

          #
          ## ExSlop
          #
          {ExSlop.Check.Readability.NarratorDoc, []},
          {ExSlop.Check.Readability.BoilerplateDocParams, []},
          {ExSlop.Check.Readability.ObviousComment, [additional_keywords: []]},
          {ExSlop.Check.Readability.StepComment, []},
          {ExSlop.Check.Readability.NarratorComment, []},
          {ExSlop.Check.Readability.UnaliasedModuleUse, []},
          {ExSlop.Check.Refactor.FilterNil, []},
          {ExSlop.Check.Refactor.RejectNil, []},
          {ExSlop.Check.Refactor.ReduceAsMap, []},
          {ExSlop.Check.Refactor.MapIntoLiteral, []},
          {ExSlop.Check.Refactor.IdentityPassthrough, []},
          {ExSlop.Check.Refactor.IdentityMap, []},
          {ExSlop.Check.Refactor.CaseTrueFalse, []},
          {ExSlop.Check.Refactor.TryRescueWithSafeAlternative, []},
          {ExSlop.Check.Refactor.WithIdentityElse, []},
          {ExSlop.Check.Refactor.WithIdentityDo, []},
          {ExSlop.Check.Refactor.SortThenReverse, []},
          {ExSlop.Check.Refactor.StringConcatInReduce, []},
          {ExSlop.Check.Refactor.ReduceMapPut, []},
          {ExSlop.Check.Refactor.RedundantBooleanIf, []},
          {ExSlop.Check.Refactor.FlatMapFilter, []},
          {ExSlop.Check.Refactor.RedundantEnumJoinSeparator, []},
          {ExSlop.Check.Refactor.UseMapJoin, []},
          {ExSlop.Check.Refactor.PreferEnumSlice, []},
          {ExSlop.Check.Refactor.GraphemesLength, []},
          {ExSlop.Check.Refactor.ManualStringReverse, []},
          {ExSlop.Check.Refactor.SortThenAt, []},
          {ExSlop.Check.Refactor.SortForTopK, []},
          {ExSlop.Check.Refactor.ListFold, []},
          {ExSlop.Check.Refactor.ListLast, []},
          {ExSlop.Check.Refactor.LengthInGuard, []},
          {ExSlop.Check.Refactor.ExplicitSumReduce, []},
          {ExSlop.Check.Warning.BlanketRescue, []},
          {ExSlop.Check.Warning.RescueWithoutReraise, []},
          {ExSlop.Check.Warning.RepoAllThenFilter, []},
          {ExSlop.Check.Warning.QueryInEnumMap, []},
          {ExSlop.Check.Warning.GenserverAsKvStore, []},
          {ExSlop.Check.Warning.PathExpandPriv, []},
          {ExSlop.Check.Warning.DualKeyAccess, []},

          #
          ## Jump
          #
          {Jump.CredoChecks.PreferChangeOverUpDownMigrations},
          {Jump.CredoChecks.PreferTextColumns},
          {Jump.CredoChecks.AssertReceiveTimeout, []},
          {Jump.CredoChecks.AvoidFunctionLevelElse, []},
          {Jump.CredoChecks.AvoidLoggerConfigureInTest, []},
          {Jump.CredoChecks.ConditionalAssertion, []},
          {Jump.CredoChecks.DoctestIExExamples,
           [
             # Tells Credo where to look for the `doctest` call. If you colocate your test files
             # with your implementation, this would just be
             # `&String.replace_trailing(&1, ".ex", "_test.exs")`
             derive_test_path: fn filename ->
               filename
               |> String.replace_leading("lib/", "test/")
               |> String.replace_trailing(".ex", "_test.exs")
             end
           ]},
          {Jump.CredoChecks.ForbiddenFunction,
           functions: [
             {:erlang, :binary_to_term, "Use Plug.Crypto.non_executable_binary_to_term/2 instead."}
           ]},
          {Jump.CredoChecks.UndeclaredExternalResource, []},
          {Jump.CredoChecks.TestHasNoAssertions, custom_assertion_functions: []},
          {Jump.CredoChecks.TooManyAssertions, [max_assertions: 20]},
          {Jump.CredoChecks.TopLevelAliasImportRequire, []},
          {Jump.CredoChecks.VacuousTest,
           [
             # When true, tests that destructure setup context (3-arity test blocks) are
             # considered not vacuous.
             ignore_setup_only_tests?: false,
             # Additional library namespaces whose calls should not count as production code.
             library_modules: []
           ]},
          {Jump.CredoChecks.WeakAssertion, []},
          {Jump.CredoChecks.NoManualContentDisposition, []},
          {Jump.CredoChecks.AvoidModifyingStructBeforeChangeset, []},
          {Jump.CredoChecks.NoWordSigilInterpolation, []},

          #
          # Oeditus
          #
          # Error Handling
          {OeditusCredo.Check.Warning.MissingErrorHandling, [exclude_test_files: true]},
          {OeditusCredo.Check.Warning.SilentErrorCase, []},
          {OeditusCredo.Check.Warning.SwallowingException, []},
          # Database & Performance
          {OeditusCredo.Check.Warning.InefficientFilter, []},
          {OeditusCredo.Check.Warning.NPlusOneQuery, []},
          {OeditusCredo.Check.Warning.MissingPreload, []},
          # LiveView & Concurrency
          {OeditusCredo.Check.Warning.UnmanagedTask, []},
          {OeditusCredo.Check.Warning.SyncOverAsync, []},
          {OeditusCredo.Check.Warning.MissingHandleAsync, []},
          {OeditusCredo.Check.Warning.MissingThrottle, []},
          {OeditusCredo.Check.Warning.InlineJavascript, []},
          # Code Quality
          {OeditusCredo.Check.Warning.DirectStructUpdate, []},
          {OeditusCredo.Check.Warning.CallbackHell, [max_nesting: 2]},
          {OeditusCredo.Check.Warning.BlockingInPlug, []},
          # Code Organization & Idiomatic Refactoring
          {OeditusCredo.Check.Refactoring.PreferMultiHeadFunction, []},
          {OeditusCredo.Check.Refactoring.PreferMultiHeadForNil, []},
          {OeditusCredo.Check.Refactoring.PreferPipelineOperator, [exclude_test_files: true]},
          {OeditusCredo.Check.Refactoring.PreferInplaceMapMatching, []},
          {OeditusCredo.Check.Refactoring.PreferInplaceListMatching, []},
          {OeditusCredo.Check.Refactoring.PreferInplaceBinaryMatching, []},
          {OeditusCredo.Check.Refactoring.PreferDestructuring, []},
          {OeditusCredo.Check.Refactoring.PreferDotAccessForStructs, []},
          {OeditusCredo.Check.Refactoring.PreferWithClause, []},
          {OeditusCredo.Check.Refactoring.PreferTaggedTuplesForErrors, []},
          {OeditusCredo.Check.Refactoring.PreferForComprehensionOverFilterMap, []},
          {OeditusCredo.Check.Refactoring.PreferPatternMatchingForEmptiness, []},
          {OeditusCredo.Check.Refactoring.PreferStringBoundariesOverRegex, []},
          {OeditusCredo.Check.Refactoring.PreferFunctionCapture, []},
          {OeditusCredo.Check.Refactoring.PreferShortFieldAccessCapture, []},
          {OeditusCredo.Check.Refactoring.PreferMapMerge, []},
          {OeditusCredo.Check.Refactoring.AvoidUnawaitedTaskAsync, []},
          # Refactoring Suggestions
          {OeditusCredo.Check.Refactoring.SuggestFSM, []},
          # Telemetry & Observability
          {OeditusCredo.Check.Warning.TelemetryInRecursiveFunction, [priority: :low, exit_status: 0]},
          {OeditusCredo.Check.Warning.MissingTelemetryInAuthPlug, [priority: :low, exit_status: 0]},
          {OeditusCredo.Check.Warning.MissingTelemetryForExternalHttp, [priority: :low, exit_status: 0]},
          # Security - Injection
          {OeditusCredo.Check.Security.SQLInjection, []},
          {OeditusCredo.Check.Security.OSCommandInjection, []},
          {OeditusCredo.Check.Security.CodeInjection, []},
          {OeditusCredo.Check.Security.XSSVulnerability, []},
          # Security - Auth
          {OeditusCredo.Check.Security.MissingAuthentication, []},
          {OeditusCredo.Check.Security.MissingAuthorization, []},
          {OeditusCredo.Check.Security.IncorrectAuthorization, []},
          {OeditusCredo.Check.Security.InsecureDirectObjectReference, []},
          # Security - Data Protection
          {OeditusCredo.Check.Security.SensitiveDataExposure, []},
          {OeditusCredo.Check.Security.HardcodedCredentials, []},
          {OeditusCredo.Check.Security.UnsafeDeserialization, []},
          # Security - Input & File Handling
          {OeditusCredo.Check.Security.ImproperInputValidation, []},
          {OeditusCredo.Check.Security.PathTraversal, []},
          {OeditusCredo.Check.Security.UnrestrictedFileUpload, []},
          # Security - Web
          {OeditusCredo.Check.Security.MissingCSRFProtection, [exclude_test_files: true]},
          {OeditusCredo.Check.Security.SSRFVulnerability, []},
          # Security - Race Conditions
          {OeditusCredo.Check.Security.TOCTOU, []}
        ],
        disabled: [
          #
          # Controversial and experimental checks (opt-in, just move the check to `:enabled`
          #   and be sure to use `mix credo --strict` to see low priority checks)
          #
          {Credo.Check.Consistency.UnusedVariableNames, []},
          {Credo.Check.Design.DuplicatedCode, []},
          {Credo.Check.Readability.AliasAs, []},
          {Credo.Check.Readability.ImplTrue, []},
          {Credo.Check.Readability.NestedFunctionCalls, []},
          {Credo.Check.Readability.SeparateAliasRequire, []},
          {Credo.Check.Readability.SingleFunctionToBlockPipe, []},
          {Credo.Check.Readability.Specs, []},
          {Credo.Check.Readability.WithCustomTaggedTuple, []},
          {Credo.Check.Refactor.ABCSize, []},
          {Credo.Check.Refactor.CondInsteadOfIfElse, []},
          {Credo.Check.Refactor.FilterReject, []},
          {Credo.Check.Refactor.IoPuts, []},
          {Credo.Check.Refactor.ModuleDependencies, []},
          {Credo.Check.Refactor.NegatedIsNil, []},
          {Credo.Check.Refactor.PassAsyncInTestCases, []},
          {Credo.Check.Refactor.RejectFilter, []},
          {Credo.Check.Refactor.VariableRebinding, []},
          {Credo.Check.Warning.LazyLogging, []},
          {Credo.Check.Warning.LeakyEnvironment, []},
          {Credo.Check.Warning.MapGetUnsafePass, []},
          {Credo.Check.Warning.MixEnv, []},

          # {Credo.Check.Warning.UnusedOperation, [{MyMagicModule, [:fun1, :fun2]}]}
          # {Credo.Check.Refactor.MapInto, []},

          # ExSlop
          {ExSlop.Check.Readability.DocFalseOnPublicFunction, []},

          # Jump
          {Jump.CredoChecks.AssertElementSelectorCanNeverFail, []},
          # Default exclusion list is empty
          {Jump.CredoChecks.AvoidSocketAssignsInTest, excluded: ["test/app_web/plugs/"]},
          {Jump.CredoChecks.LiveViewFormCanBeRehydrated, excluded: ["lib/my_app/"]},
          # Exclude files that intentionally decode fully-trusted (never attacker-controlled) input
          {Jump.CredoChecks.SafeBinaryToTerm, files: %{excluded: ["lib/my_app/trusted_decoder.ex"]}},
          {Jump.CredoChecks.UnusedLiveViewAssign,
           [
             ignored_assigns: [:active_path],
             # Optional helpers that write assigns like Phoenix.Component.assign/3
             custom_assign_functions: [
               {:assign_current_user, 3},
               {MyApp.LiveHelpers, :assign_tenant, 3}
             ]
           ]},
          {Jump.CredoChecks.LiveViewPubSubRequiresConnected, []},
          {Jump.CredoChecks.UseObanProWorker, []},

          # Oeditus
          {OeditusCredo.Check.Refactoring.ChangeRiskAntiPatterns, []},
          {OeditusCredo.Check.Warning.UnsafeMapAccess, []},
          {OeditusCredo.Check.Readability.UnnecessaryInterpolatingSigil, []},
          {OeditusCredo.Check.Refactoring.PreferCasePatternMatching, []},
          {OeditusCredo.Check.Refactoring.AvoidSinglePipe, []},
          {OeditusCredo.Check.Refactoring.PreferListPrepend, []}

          #
          # Custom checks can be created using `mix credo.gen.check`.
          #
        ]
      }
    }
  ]
}
