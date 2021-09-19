var app = new Vue({
  el: '#app',
  data: {
    message: 'Hello Vue!'
  },
  methods: {
    greet: async function() {
      send({ type: 'llOwnerSay', message: 'Hello world!' });
    }
  }
});
