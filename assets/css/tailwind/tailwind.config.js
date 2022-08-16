module.exports = {
  content: [
    '../../../lib/lenny_web/**/*.ex',
    '../../../lib/lenny_web/**/*.html.heex',
    '../../../assets/**/*.js'
  ],
  theme: {
    screens: {
      'sm': '640px',
      'md': '768px',
      'lg': '1024px'
    }
  },
  variants: {
    extend: {},
  },
  plugins: [
    require('@tailwindcss/forms'),
  ],
}
