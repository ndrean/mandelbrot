defmodule Chart do
  def data(m, c) do
    points =
      with list <- Mand.orb(m, c),
           [n, l] = list,
           true <- is_integer(n) do
        Nx.concatenate(l)
        |> Nx.to_flat_list()
        |> Enum.chunk_every(4)
        |> Enum.map(fn [x, _, y, _] -> [x, y] end)
      else
        _ ->
          Nx.concatenate(list)
          |> Nx.to_flat_list()
          |> Enum.chunk_every(4)
          |> Enum.map(fn [x, _, y, _] -> [x, y] end)
      end
  end
end

# for i <- 0..m-1 do
#  %{"x" => Enum.at(Enum.at(points, i), 0), "y" => Enum.at(Enum.at(points, i), 1)}
# end
