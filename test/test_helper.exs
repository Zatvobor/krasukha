for path <- Path.wildcard("./test/shared/*_behavior.exs"), do: Code.load_file(path)

ExUnit.configure(exclude: [external: true])
ExUnit.start()
