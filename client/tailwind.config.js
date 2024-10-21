/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/index.html",
    "./src/**/*.gleam"
  ],
  theme: {
    extend: {
      colors: {
        "light-shades": "#F2F1F4",
        "light-accent": "#C2CAD6",
        "main-brand": "#677A98",
        "dark-accent": "#52627A",
        "dark-shades": "#1E2030",
      }
    },
  },
  plugins: [],
}

