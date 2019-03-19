defmodule BlockScoutWeb.API.RPC.ContractController do
  use BlockScoutWeb, :controller

  alias BlockScoutWeb.API.RPC.Helpers
  alias Explorer.Chain

  def listcontracts(conn, params) do
    options =
      params
      |> optional_params()
      |> Map.put_new(:page_number, 0)
      |> Map.put_new(:page_size, 10)

    contracts = list_contracts(options)

    conn
    |> put_status(200)
    |> render(:listcontracts, %{contracts: contracts})
  end

  def getabi(conn, params) do
    with {:address_param, {:ok, address_param}} <- fetch_address(params),
         {:format, {:ok, address_hash}} <- to_address_hash(address_param),
         {:contract, {:ok, contract}} <- to_smart_contract(address_hash) do
      render(conn, :getabi, %{abi: contract.abi})
    else
      {:address_param, :error} ->
        render(conn, :error, error: "Query parameter address is required")

      {:format, :error} ->
        render(conn, :error, error: "Invalid address hash")

      {:contract, :not_found} ->
        render(conn, :error, error: "Contract source code not verified")
    end
  end

  def getsourcecode(conn, params) do
    with {:address_param, {:ok, address_param}} <- fetch_address(params),
         {:format, {:ok, address_hash}} <- to_address_hash(address_param),
         {:contract, {:ok, contract}} <- to_smart_contract(address_hash) do
      render(conn, :getsourcecode, %{contract: contract, address_hash: address_hash})
    else
      {:address_param, :error} ->
        render(conn, :error, error: "Query parameter address is required")

      {:format, :error} ->
        render(conn, :error, error: "Invalid address hash")

      {:contract, :not_found} ->
        render(conn, :getsourcecode, %{contract: nil, address_hash: nil})
    end
  end

  defp list_contracts(%{page_number: page_number, page_size: page_size} = opts) do
    offset = (max(page_number, 1) - 1) * page_size

    case Map.get(opts, :filter) do
      :verified ->
        Chain.list_verified_contracts(page_size, offset)

      # :decompiled ->
      #   Chain.list_decompiled_contracts(params)

      :unverified ->
        Chain.list_unverified_contracts(page_size, offset)

      # :not_decompiled ->
      #   Chain.list_not_decompiled_contracts(params)

      _ ->
        Chain.list_contracts(page_size, offset)
    end
  end

  defp optional_params(params) do
    %{}
    |> Helpers.put_pagination_options(params)
    |> add_filter(params)
  end

  defp add_filter(options, params) do
    filter =
      params
      |> Map.get("filter")
      |> contracts_filter()

    Map.put(options, :filter, filter)
  end

  defp contracts_filter(nil), do: nil
  defp contracts_filter(1), do: :verified
  defp contracts_filter(2), do: :decompiled
  defp contracts_filter(3), do: :unverified
  defp contracts_filter(4), do: :not_decompiled
  defp contracts_filter("verified"), do: :verified
  defp contracts_filter("decompiled"), do: :decompiled
  defp contracts_filter("unverified"), do: :unverified
  defp contracts_filter("not_decompiled"), do: :not_decompiled

  defp contracts_filter(filter) when is_bitstring(filter) do
    case Integer.parse(filter) do
      {number, ""} -> contracts_filter(number)
      _ -> nil
    end
  end

  defp contracts_filter(_), do: nil

  defp fetch_address(params) do
    {:address_param, Map.fetch(params, "address")}
  end

  defp to_address_hash(address_hash_string) do
    {:format, Chain.string_to_address_hash(address_hash_string)}
  end

  defp to_smart_contract(address_hash) do
    result =
      case Chain.address_hash_to_smart_contract(address_hash) do
        nil -> :not_found
        contract -> {:ok, contract}
      end

    {:contract, result}
  end
end
