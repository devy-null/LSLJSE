var app = new Vue({
  el: '#app',
  data: {
    name: '',
    message: '',
    messages: []
  },
  created() {
    document.addEventListener('broadcast', (event) => {
      if (event.detail.type == 'message') {
        this.messages.push({
          author: event.detail.author,
          text: event.detail.message
        });
    
        console.log('A', event.detail);
      }
    });

    NameLookup.Instance.lookup(base_data['avatar']).then(name => this.name = name);
  },
  methods: {
    sendMessage: function () {
      send({ type: 'broadcast', payload: { type: 'message', author: this.name, message: this.message } });
      this.message = '';
    }
  }
});

