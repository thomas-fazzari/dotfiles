return {
  settings = {
    yaml = {
      -- SchemaStore.nvim supplies the catalog, so yamlls' own download is turned off
      schemaStore = { enable = false, url = "" },
      schemas = require("schemastore").yaml.schemas(),
    },
  },
}
