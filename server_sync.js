// https://stackoverflow.com/a/2117523
function uuidv4() {
	return ([1e7] + -1e3 + -4e3 + -8e3 + -1e11).replace(/[018]/g, c => (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16));
}

const base_data = JSON.parse(atob(document.location.hash.substring(1)) || "{}");

let gitApp;

async function getApps() {
	let pull_requests = await (await fetch('https://api.github.com/repos/devy-null/LSLJSE/pulls')).json();

	let apps = pull_requests
		.filter(pr => pr.base.label == 'devy-null:main')
		.map(pr => ({
			id: pr.head.label,
			name: pr.title,
			description: pr.body,
			created: pr.created_at,
			updated: pr.updated_at,
			is_official: pr.author_association == 'OWNER',
			author: {
				img: pr.user.avatar_url,
				name: pr.user.login
			},
			pull_request: pr
		}));

	return apps;
}

function ack(data) {
	document.dispatchEvent(new CustomEvent('server_ack', { detail: data }));
}

function poll_response(queue) {
	document.dispatchEvent(new CustomEvent('server_poll_response', { detail: queue }));
}

async function getURL() {
	var response = await fetch('https://quintadb.com/search/c5W7ldOmnkW6KeWQxdOSke.json?entity_id=cStv9tW4zcOOouwxSskGXa',
		{
			method: 'POST',
			headers: {
				'Content-Type': 'application/json'
			},
			body: JSON.stringify({
				"rest_api_key": "c3WPSgC3LmW7ZdMaLMWODL",
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

async function getRLVRestrictions() {
	return (await sendRLV('@getstatusall:;	')).split('	');
}

async function sendRLV(cmd) {
	let response = await send({ type: "RLV", cmd: cmd });

	if (response.status == "ok") return response.value;
	else throw { message: response.status };
}

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
		src.searchParams.set('message', btoa(JSON.stringify(data || {})));

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

				if (event.detail.status == "ok") {
					resolve(event.detail);
				}
				else {
					reject({ message: event.detail.status });
				}
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
				await send_json('ping').catch(err => { throw { message: 'Lost url', cause: err } });
			}
			else {
				throw { message: 'Lost url' };
			}
		}
	}
}

function postRawData(url, data) {
	let iframe = document.createElement('iframe');
	iframe.name = uuidv4();
	//iframe.style.display = 'none';
	document.body.appendChild(iframe);

	document.addEventListener('message', function (msg) {
		console.log('iframe msg', msg);
	});

	let form = document.createElement('form');
	form.method = 'POST';
	form.action = url;
	form.target = iframe.name;

	for (let [k, v] of Object.entries(data)) {
		let dataInput = document.createElement('input');
		dataInput.type = 'hidden';
		dataInput.name = k;
		dataInput.value = (v && v instanceof Object) ? JSON.stringify(v) : v;
		form.appendChild(dataInput);
	}

	document.body.appendChild(form);

	form.submit();

	//document.body.removeChild(iframe);
	//document.body.removeChild(form);
}

async function loadApp(app) {
	let getFile = async (path) => {
		let downloadPath;

		if (new URL(location).searchParams.get('localhost') == 'true') {
			downloadPath = `http://127.0.0.1:8080/App/${path}`;
		}
		else {
			let filePath = app.pull_request.head.repo.contents_url.replace("{+path}", path) + '?ref=' + app.pull_request.head.ref;
			let info = await (await fetch(filePath)).json();
			downloadPath = info.download_url;
		}

		return await (await fetch(downloadPath)).text();
	};

	let html = await getFile('app.body');
	let css = await getFile('app.css');
	let js = await getFile('app.js');

	document.body.innerHTML = html;

	let script = document.createElement('script');
	script.text = js;
	document.body.prepend(script);

	let style = document.createElement('style');
	style.text = css;
	document.body.prepend(style);
}

function showError(text) {
	new Vue({
		el: '#app',
		data: {
			message: `Error: ${text}`
		}
	});
}

async function main() {
	if (!base_data || !base_data['app'] || !base_data['avatar'] || !base_data['token'] || !base_data['page']) {
		showError('Invalid url')
	}
	else {
		gitApp = (await getApps()).find(app => app.id == base_data['page']);

		if (gitApp) {
			let fetchedURL = await server_url_promise.catch(err => null);

			if (fetchedURL) {
				loadApp(gitApp);
				start_poll();
			}
			else {
				showError(`Can't connect!`);
			}
		}
		else {
			showError('Invalid app');
		}
	}
}

main();