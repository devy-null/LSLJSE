// https://stackoverflow.com/a/2117523
function uuidv4() {
	return ([1e7] + -1e3 + -4e3 + -8e3 + -1e11).replace(/[018]/g, c => (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16));
}

function ack(data) {
	document.dispatchEvent(new CustomEvent('server_ack', { detail: data }));
}

function poll_response(queue) {
	document.dispatchEvent(new CustomEvent('server_poll_response', { detail: queue }));
}

const base_data = JSON.parse(atob(document.location.hash.substring(1)));

if (!base_data || !base_data['app'] || !base_data['avatar'] || !base_data['token'] /*|| !base_data['page']*/)
{
	throw 'Invalid url';
}

async function getURL() {
	var response = await fetch('https://quintadb.com/search/c5W7ldOmnkW6KeWQxdOSke.json?entity_id=cStv9tW4zcOOouwxSskGXa',
		{
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				'Authorization': 'Basic ' + btoa('JavascriptEngine:qb9w8mLJ6cZrfAy')
			},
			body: JSON.stringify({
				"search": [[
					{
						"a": "aCvYRdJSnbAQz1CGlcRmoW",
						"o": "is",
						"b": base_data['app']
					}
				]]
			})
		});

	var records = (await response.json()).records;

	return records[0].values["cyW44jWODdUy7cNCorWPaD"];
}

let server_url_promise = getURL();

async function send(data, timeout) {
	return new Promise(async (resolve, reject) => {
		let { message_id } = await send_json('post', data);
		let key = 'message::' + message_id;
		let listener;
		let timeoutid;

		let cleanup = () => {
			document.removeEventListener(key, listener);
			if (timeoutid) clearTimeout(timeoutid);
		};

		listener = (ev) => {
			cleanup();
			resolve(ev.detail);
		};

		if (timeout) {
			setTimeout(() => {
				cleanup();
				reject({ cause: 'timeout' });
			}, timeout);
		}

		document.addEventListener(key, listener);
	});
}

function send_json(path, data) {
	let message_id = uuidv4();

	let promise = new Promise(async (resolve, reject) => {
		let src = new URL(await server_url_promise);
		src.pathname += "/" + path;
		src.searchParams.set('message_id', message_id);
		src.searchParams.set('message', JSON.stringify(data || {}));

		src.searchParams.set('app', base_data['app']);
		src.searchParams.set('avatar', base_data['avatar']);
		src.searchParams.set('token', base_data['token']);

		let script = document.createElement('script');
		script.type = 'text/javascript';

		let done = false;
		let start = new Date();

		let timeoutid;
		let cleanup;

		script.onerror = () => {
			cleanup();

			if (new Date().getTime() - start.getTime() > 20000) {
				reject({ cause: 'timeout' });
			}
			else {
				reject({ cause: 'load' });
			}
		};

		script.onload = () => {
			if (!done) {
				cleanup();
				reject({ cause: 'jsonp' });
			}
		};

		let listener = (event) => {
			if (path == 'poll' || event.detail.message_id == message_id) {
				cleanup();

				done = true;

				resolve(event.detail);
			}
		};

		let responder = path == 'poll' ? 'server_poll_response' : 'server_ack';

		document.addEventListener(responder, listener);

		timeoutid = setTimeout(() => {
			cleanup();
			reject({ cause: 'timeout' });
		}, 25000);

		cleanup = () => {
			clearTimeout(timeoutid);
			document.removeEventListener(responder, listener);
			delete script.onerror;
			delete script.onload;
			script.src = '';
		};

		script.src = src;
		document.body.appendChild(script);
		document.body.removeChild(script);
	});

	return promise;
}

document.addEventListener('polled', (ev) => {
	for (let message of ev.detail) {
		if ('message_id' in message) {
			document.dispatchEvent(new CustomEvent('message::' + message['message_id'], { detail: message.data }));
		}
		else {
			document.dispatchEvent(new CustomEvent('message', { detail: message }));
			console.log('polled', message);
		}
	}
});

async function start_poll() {
	while (true) {
		let error;

		do {
			error = undefined;

			await send_json('poll')
				.then(queue => {
					document.dispatchEvent(new CustomEvent('polled', { detail: queue }));
				})
				.catch(err => error = err);
		}
		while (!error || error.cause == 'timeout');

		if (error.cause == 'load') {
			let newurlpromise = getURL();
			let newurl = await newurlpromise;
			let oldurl = await server_url_promise;

			if (newurl != oldurl) {
				server_url_promise = newurlpromise;
				await send_json('ping').catch(err => { throw 'Lost url'; });
			}
			else {
				throw 'Lost url';
			}
		}
	}
}

start_poll();