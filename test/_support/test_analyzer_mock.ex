defmodule Clr.Analyzer.Api do
  @callback do_evaluate(Clr.Function.t(), args :: [term]) :: Clr.Function.t()
end

Mox.defmock(ClrTest.AnalyzerMock, for: Clr.Analyzer.Api)
