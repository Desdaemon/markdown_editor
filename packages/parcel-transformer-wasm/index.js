import { Transformer, Resolver } from "@parcel/plugin";

export default new Transformer({
  async parse({ asset, logger }) {
    // We depend on a resolver to help us point bare directory
    // imports from a Rust project, so what we should be having now is a TOML asset.
    if (asset.type !== "toml") {
      logger.error(
        `Unexpected asset type ${asset.type}, expected a TOML asset.`
      );
      return;
    }

    // Check if Rust is installed.
    installRust();
  },
});

function installRust() {}
