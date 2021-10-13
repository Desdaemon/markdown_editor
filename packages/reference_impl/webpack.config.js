const path = require("path");
const { ContextReplacementPlugin } = require("webpack");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const WasmPackPlugin = require("@wasm-tool/wasm-pack-plugin");

const swcOptions = {
  jsc: {
    parser: {
      syntax: "typescript",
    },
    target: "es2016",
  },
};

module.exports = {
  mode: "development",
  entry: "./src/index.ts",
  devtool: "inline-source-map",
  devServer: {
    static: "./dist",
  },
  resolve: {
    extensions: ["", ".js", ".ts"],
  },
  // stats: "summary",
  plugins: [
    new HtmlWebpackPlugin({
      title: "Markdown Editor (dev)",
    }),
    new WasmPackPlugin({
      crateDirectory: path.resolve(__dirname, "../rust-md"),
    }),
    new ContextReplacementPlugin(/\/petite-vue\//, (data) => {
      delete data.dependencies[0].critical;
      return data;
    }),
  ],
  experiments: {
    asyncWebAssembly: true,
  },
  module: {
    rules: [
      {
        test: /\.(j|t)s?$/,
        exclude: /node_modules/,
        use: {
          loader: "swc-loader",
          options: swcOptions,
        },
      },
      {
        test: /\.css$/,
        use: ["style-loader", "css-loader"],
      },
    ],
  },
};
