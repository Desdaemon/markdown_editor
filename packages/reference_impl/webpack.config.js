const path = require("path");
const { ContextReplacementPlugin } = require("webpack");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const WasmPackPlugin = require("@wasm-tool/wasm-pack-plugin");
const { BundleAnalyzerPlugin } = require("webpack-bundle-analyzer");

const swcOptions = {
  jsc: {
    parser: {
      syntax: "typescript",
    },
    target: "es2016",
  },
};

module.exports = {
  mode: "production",
  entry: "./src/index.ts",
  devServer: {
    static: "./dist",
  },
  output: {
    clean: true,
  },
  resolve: {
    extensions: ["", ".js", ".ts"],
  },
  stats: "summary",
  plugins: [
    new HtmlWebpackPlugin({
      title: "Markdown Editor",
    }),
    new WasmPackPlugin({
      crateDirectory: path.resolve(__dirname, "../rust-md"),
    }),
    new ContextReplacementPlugin(/\/petite-vue\//, (data) => {
      delete data.dependencies[0].critical;
      return data;
    }),
    new BundleAnalyzerPlugin(),
  ],
  experiments: {
    asyncWebAssembly: true,
  },
  module: {
    rules: [
      {
        test: /\.ts?$/,
        exclude: /(node_modules|bower_components)/,
        use: {
          loader: "swc-loader",
          options: swcOptions,
        },
      },
      {
        test: /\.css$/,
        use: ["style-loader", "css-loader"],
      },
      {
        test: /\.md$/,
        type: "asset",
      },
    ],
  },
};
