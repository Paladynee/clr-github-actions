defmodule Clr.Analyzer.Api do
  @callback analyze(Clr.Block.t(), code :: Clr.Air.codeblock()) :: Clr.Block.t()
end

Mox.defmock(ClrTest.AnalyzerMock, for: Clr.Analyzer.Api)
