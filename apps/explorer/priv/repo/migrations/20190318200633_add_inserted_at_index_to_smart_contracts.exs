defmodule Explorer.Repo.Migrations.AddInsertedAtIndexToSmartContracts do
  use Ecto.Migration

  def change do
    create(index(:smart_contracts, :inserted_at))
  end
end
