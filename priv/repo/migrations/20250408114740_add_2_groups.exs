defmodule Scaped.Repo.Migrations.Add2Groups do
  alias Scaped.Groups.Group
  use Ecto.Migration

  def change do
    permutations = [[1, 2], [2, 1]]

    for i <- permutations, j <- permutations do
      cs = Group.changeset(%Group{}, %{images: i, conditions: j})
      Scaped.Repo.insert(cs)
    end

    first_group = Scaped.Repo.get!(Group, 1)
    first_group = Ecto.Changeset.change(first_group, pointer: true)
    Scaped.Repo.update!(first_group)
    
  end
end
