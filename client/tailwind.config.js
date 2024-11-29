/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/index.html", "./src/**/*.gleam"],
  theme: {
    extend: {
      colors: {
        "light-shades": "#F2F1F4",
        "light-accent": "#C2CAD6",
        "main-brand": "#EFF1F4",
        "dark-accent": "#DCDFE4",
        "dark-shades": "#1E2030",
        dark: {
          "main-brand": "#677A98",
          "dark-accent": "#52627A",
        },
      },
      boxShadow: {
        outer: "0px 0px 4px 4px rgba(0, 0, 0, 0.1)",
      },
    },
  },
  plugins: [],
};
