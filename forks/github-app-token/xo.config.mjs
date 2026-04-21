import sortDestructureKeys from "eslint-plugin-sort-destructure-keys";
import typescriptSortKeys from "eslint-plugin-typescript-sort-keys";

/** @type {import('xo').FlatXoConfig} */
const xoConfig = [
  {
    prettier: "compat",
    plugins: {
      "sort-destructure-keys": sortDestructureKeys,
      "typescript-sort-keys": typescriptSortKeys,
    },
    rules: {
      "@typescript-eslint/naming-convention": "off",
      "func-style": ["error", "expression", { allowArrowFunctions: true }],
      "import-x/namespace": "off",
      "import-x/no-default-export": "error",
      "import-x/no-extraneous-dependencies": [
        "error",
        {
          devDependencies: false,
          optionalDependencies: false,
          peerDependencies: false,
        },
      ],
      "import-x/no-namespace": "error",
      "no-console": "error",
      "object-shorthand": [
        "error",
        "always",
        { avoidExplicitReturnArrows: true },
      ],
      "sort-destructure-keys/sort-destructure-keys": [
        "error",
        {
          caseSensitive: false,
        },
      ],
      "sort-keys": [
        "error",
        "asc",
        {
          caseSensitive: false,
          minKeys: 2,
          natural: true,
        },
      ],
      "typescript-sort-keys/interface": "error",
      "typescript-sort-keys/string-enum": "error",
    },
  },
  {
    files: ["**/*.{ts,tsx}"],
    rules: {
      // Covered by TypeScript.
      "default-case": "off",
    },
  },
];

export default xoConfig;
