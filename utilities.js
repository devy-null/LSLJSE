async function getRLVRestrictions() {
    let local_restrictions = (await sendRLV('@getstatus:;	')).split('	');
    let blocked_restrictions = (await sendRLV('@getstatusall:;	')).split('	');

    let rlvcmdregex = /^(?<cmd>.*?)(?::(?<option>.*))?$/i;

    return blocked_restrictions.reduce((total, restriction) => {
      let match = rlvcmdregex.exec(restriction);
      let obj = total[match.groups['cmd']] = total[match.groups['cmd']] || {};

      if (match.groups['option']) {
        let options = obj['options'] = obj['options'] || [];
        options.push({
          value: match.groups['option'],
          local: local_restrictions.includes(restriction),
          another: !local_restrictions.includes(restriction) || blocked_restrictions.reduce((tot, r) => tot + (r == restriction ? 1 : 0), 0) != 1
        })
      } else {
        obj.active = true;
        obj.local = local_restrictions.includes(restriction);
        obj.another = !local_restrictions.includes(restriction) || blocked_restrictions.reduce((tot, r) => tot + (r == restriction ? 1 : 0), 0) != 1;
      }

      return total;
    }, {});
}

async function sendRLV(cmd) {
    return await send({ type: "RLV", cmd: cmd });
}

async function say(text, channel = 0, name = undefined) {
    return await send({ "type": "llSay", "name": name, "text": text, channel: channel });
}

class AvatarRestrictions {
    // remember recvchat_sec
    recvchat; // exception
    recvchatfrom; // block

    // remember recvemote_sec
    recvemote; // exception
    recvemotefrom; // block

    // remember sendim_sec
    sendim; // exception
    sendimto; // block

    startim; // exception
    startimto; // block

    // remember recvim_sec
    recvim; // exception
    recvimfrom; // block

    // remember tplure_sec
    tplure; // exception

    accepttp; // auto
    accepttprequest; // auto

    // remember tprequest_sec
    tprequest; // exception

    share; // exception

    touchattachother; // block

    // remember shownames_sec
    shownames; // exception
}

class ChatListener {
    constructor(sessionid, channel, filter) {
        this.sessionid = sessionid;
        this.channel = channel;
        this.active = true;
        this.listeners = [];
        this.filter = filter;

        this.pingid = setInterval(async () => {
            await send({ type: 'register_chat_listener', channel: this.channel, session: this.sessionid });
        }, 20000);

        this.listener = (e) => {
            if (e.detail.channel == this.channel) {
                if (this.filter && !this.filter(e.detail)) return;

                this.listeners.forEach(listener => {
                    try {
                        listener.call(this, e.detail);
                    }
                    catch { }
                });
            }
        };

        document.addEventListener('SLChat', this.listener);
    }

    async awaitChat(timeout) {
        let pResolve, pReject;

        let promise = new Promise((resolve, reject) => { pResolve = resolve; pReject = reject; });

        if (!this.active) {
            pReject('inactive');
            return promise;
        }

        let timeoutid;

        if (timeout) {
            timeoutid = setTimeout(() => {
                pReject('timeout');
            }, timeout);

            promise.finally(() => { clearTimeout(timeoutid); });
        }

        let fun = (data) => {
            pResolve(data);
        };

        let remover = this.addListener(fun);
        promise.finally(() => { remover(); });

        return promise;
    }

    async awaitOneChatAndDestroy(timeout) {
        return await this.awaitChat(timeout).finally(() => {
            this.disable();
        });
    }

    addListener(fun) {
        if (!this.active) throw 'inactive';

        if (this.listeners.indexOf(fun) == -1) this.listeners.push(fun);
        return () => this.removeListener(fun);
    }

    removeListener(fun) {
        let index = this.listeners.indexOf(fun);
        if (index != -1) this.listeners.splice(index, 1);
    }

    isActive() {
        return this.active;
    }

    static createRandomChannel() {
        return Math.floor(20000 + Math.random() * 400000);
    }

    disable() {
        if (this.active) {
            clearInterval(this.pingid);
            document.removeEventListener('SLChat', this.listener);
            send({ type: 'unregister_chat_listener', session: this.sessionid });
            this.active = false;
        }
    }

    static async create(channel = 0) {
        let sessionid = await send({ type: 'register_chat_listener', channel: channel });
        return new ChatListener(sessionid, channel);
    }

    static async listenForOne(channel = 0, timeout) {
        let listener = await this.create(channel);
        let chat = await listener.awaitChat(timeout).finally(() => { listener.disable(); });
        return chat;
    }
}

class RLVNotifyListener extends ChatListener {
    constructor(sessionid, channel, cmd) {
        super(sessionid, channel);
        this.cmd = cmd;

        this.filter = (e) => {
            this.filter = undefined;
            return false;
        };
    }

    disable() {
        if (this.active) {
            send({ type: 'RLV', cmd: this.cmd + '=rem' });
            super.disable();
        }
    }

    static async create(words = [], channel = undefined) {
        channel = channel || ChatListener.createRandomChannel();

        let param = words?.length > 0 ? (';' + words.join(';')) : '';
        let cmd = `@notify:${channel}${param}`;

        let sessionid = await send({ type: 'register_chat_listener', channel: channel });
        let listener = new RLVNotifyListener(sessionid, channel, cmd);
        await send({ type: 'RLV', cmd: cmd + '=add' });

        return listener;
    }
}

class Cache {
    name;
    data;

    constructor(name) {
        this.name = name;
        this.data = JSON.parse(localStorage.getItem(this.name) || '{}');
    }

    async clear() {
        this.data = {};
    }

    async haveKey(key) {
        return key in this.data;
    }

    async setItem(key, value) {
        this.data[key] = value;
        localStorage.setItem(this.name, JSON.stringify(this.data));
    }

    async getItem(key) {
        return this.data[key];
    }

    getIfCached(key) {
        return this.data[key];
    }

    async getOrFetch(key, fetcher) {
        if (!(await this.haveKey(key))) await this.setItem(key, await fetcher());
        return await this.getItem(key);
    }
}

class NameLookup {
    static Instance = new NameLookup();

    cache;

    constructor() {
        this.cache = new Cache('NameLookup');
    }

    async clear() {
        await this.cache.clear();
    }

    quickLookup(key) {
        return this.cache.getIfCached(key);
    }

    async lookup(key) {
        return await this.cache.getOrFetch(key, async () => await send({ type: 'llRequestDisplayName', key: key }).catch((err) => "(???).(???)"));
    }
}

/*
class ClickableLink
{
    constructor()
    {
        this.channel = ChatListener.createRandomChannel();
        this.chatListener = ChatListener.create(this.channel);
    }
	
    makeLink(text)
    {
        return `[secondlife:///app/chat/${this.channel}/${encodeURIComponent(text)}]`;
    }
	
    disable()
    {
        this.chatListener.disable();
    }
}
*/

async function awaitSitOnObject(id) {
    let listener = await RLVNotifyListener.create(['sat object']);

    while (true) {
        try {
            let response = await listener.awaitChat();
            let key = response.text.split(' ')[3];

            if (!id || id == key) return key;
        }
        finally {
            listener.disable();
        }
    }
}

async function awaitUnsitObject(id) {
    let listener = await RLVNotifyListener.create(['unsat object']);

    while (true) {
        try {
            let response = await listener.awaitChat();
            let key = response.text.split(' ')[3];

            if (!id || id == key) return key;
        }
        finally {
            listener.disable();
        }
    }
}

async function findPeople(minAmount = 1, maxAmount = 0) {
    return new Promise((resolve, reject) => {
        let intervalId = setInterval(async () => {
            let scanner = await sendCommand({ type: 'sensor', range: 8 });
            document.getElementById("data").textContent = JSON.stringify(scanner);
            if (scanner.length >= minAmount && (maxAmount == 0 || scanner.length <= maxAmount)) {
                clearInterval(intervalId);
                resolve(scanner);
            }
        }, 1000);
    });
}

init.then(() => {
    ChatListener.listenForOne().then(console.log);
});