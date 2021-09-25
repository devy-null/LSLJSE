var app = new Vue({
  el: '#app',
  data: {
    name: 'Mee',
    messages: []
  },
  methods: {
    sendMessage: function(text) {
      send({ type: 'broadcast', payload: { type: 'message', author: 'A', message: text } })
    }
  }
});

document.addEventListener('broadcast', (event) => {
  let detail = event.detail,
      message = detail.data;

    console.log('A', message);
});