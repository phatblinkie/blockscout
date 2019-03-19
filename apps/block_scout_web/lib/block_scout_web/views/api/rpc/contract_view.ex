defmodule BlockScoutWeb.API.RPC.ContractView do
  use BlockScoutWeb, :view

  alias BlockScoutWeb.API.RPC.RPCView
  alias Explorer.Chain.{Address, SmartContract}

  def render("listcontracts.json", %{contracts: contracts}) do
    contracts = Enum.map(contracts, &prepare_contract/1)

    RPCView.render("show.json", data: contracts)
  end

  def render("getabi.json", %{abi: abi}) do
    RPCView.render("show.json", data: Jason.encode!(abi))
  end

  def render("getsourcecode.json", %{contract: contract, address_hash: address_hash}) do
    RPCView.render("show.json", data: [prepare_contract(contract, address_hash)])
  end

  def render("error.json", assigns) do
    RPCView.render("error.json", assigns)
  end

  defp prepare_contract(address_or_contract, address_hash \\ nil)

  defp prepare_contract(nil, address_hash) do
    %{
      "Address" => to_string(address_hash),
      "SourceCode" => "",
      "ABI" => "Contract source code not verified",
      "ContractName" => "",
      "CompilerVersion" => "",
      "OptimizationUsed" => ""
    }
  end

  defp prepare_contract(%Address{hash: hash}, _) do
    %{
      "Address" => to_string(hash),
      "SourceCode" => "",
      "ABI" => "Contract source code not verified",
      "ContractName" => "",
      "CompilerVersion" => "",
      "OptimizationUsed" => ""
    }
  end

  defp prepare_contract(%SmartContract{address_hash: address_hash} = contract, _) do
    %{
      "Address" => to_string(address_hash),
      "SourceCode" => contract.contract_source_code,
      "ABI" => Jason.encode!(contract.abi),
      "ContractName" => contract.name,
      "CompilerVersion" => contract.compiler_version,
      "OptimizationUsed" => if(contract.optimization, do: "1", else: "0")
    }
  end
end
