const managed_restrictions = [
  { cmd: 'fly', description: 'When prevented, the user is unable to fly.' },
  { cmd: 'temprun', description: 'When prevented, the user is unable to run by double-tapping an arrow key.' },
  { cmd: 'alwaysrun', description: 'When prevented, the user is unable to switch running mode on by pressing Ctrl-R.' },
  { cmd: 'camunlock', description: 'When active, this restriction prevents the user from unlocking the camera from the avatar, meaning that the user cannot use Alt to focus nor orbit the camera around the avatar. ' },
  { cmd: 'sendchat', description: 'When prevented, everything typed on channel 0 will be discarded. However, emotes and messages beginning with a slash (' / ') will go through, truncated to strings of 30 and 15 characters long respectively.' },
  { cmd: 'chatshout', description: 'When prevented, the avatar will chat normally even when the user tries to shout. This does not change the message in any way, only its range.' },
  { cmd: 'chatnormal', description: 'When prevented, the avatar will whisper even when the user tries to shout or chat normally. This does not change the message in any way, only its range.' },
  { cmd: 'chatwhisper', description: 'When prevented, the avatar will chat normally even when the user tries to whisper. This does not change the message in any way, only its range.' },
  {
    cmd: 'recvchat',
    parameter: { type: 'avatar', optional: true },
    description: 'When prevented, everything heard in public chat will be discarded except emotes.'
  },
  {
    cmd: 'recvchatfrom',
    parameter: { type: 'avatar', optional: false },
    description: 'When prevented, everything heard in public chat from the specified avatar will be discarded except emotes.'
  },
  { cmd: 'sendgesture', description: 'When prevented, the user cannot send any gesture (chat, animation, sound).' },
  { cmd: 'emote', description: 'When adding this exception, the emotes are not truncated anymore (however, special signs will still discard the message).' },
  {
    cmd: 'recvemote',
    parameter: { type: 'avatar', optional: true },
    description: `When prevented, every emote seen in public chat will be discarded. When adding an exception, the user can see emotes from the sender whose UUID is specified in the command. This overrides the prevention for this avatar only (there is no limit to the number of exceptions), don't forget to remove it when it becomes obsolete.`
  },
  {
    cmd: 'recvemotefrom',
    parameter: { type: 'avatar', optional: false },
    description: 'When prevented, everything emote seen in public chat from the specified avatar will be discarded.'
  },
  {
    cmd: 'sendim',
    parameter: { type: 'avatar', optional: true },
    description: `When prevented, everything typed in IM will be discarded and a bogus message will be sent to the receiver instead. When adding an exception, the user can send IMs to the receiver whose UUID is specified in the command. This overrides the prevention for this avatar only (there is no limit to the number of exceptions), don't forget to remove it when it becomes obsolete. Since 2.9.29 you can specify a group name instead of a UUID. If you write "allgroups" instead, then all the groups are concerned.`
  },
  {
    cmd: 'sendimto',
    parameter: { type: 'avatar', optional: false },
    description: `When prevented, everything typed in IM to the specified avatar will be discarded and a bogus message will be sent instead. Since 2.9.29 you can specify a group name instead of a UUID. If you write "allgroups" instead, then all the groups are concerned. `
  },
  {
    cmd: 'startim',
    parameter: { type: 'avatar', optional: true },
    description: `When prevented, the user is unable to start an IM session with anyone. Sessions that are already open are not impacted though. When adding an exception, the user can start an IM session with the receiver whose UUID is specified in the command. This overrides the prevention for this avatar only (there is no limit to the number of exceptions), don't forget to remove it when it becomes obsolete.`
  },
  {
    cmd: 'startimto',
    parameter: { type: 'avatar', optional: false },
    description: `When prevented, the user is unable to start an IM session with that person. Sessions that are already open are not impacted though.`
  },
  {
    cmd: 'recvim',
    parameter: { type: 'avatar', optional: true },
    description: `When prevented, every incoming IM will be discarded and the sender will be notified that the user cannot read them. When adding an exception, the user can read instant messages from the sender whose UUID is specified in the command. This overrides the prevention for this avatar only (there is no limit to the number of exceptions), don't forget to remove it when it becomes obsolete. Since 2.9.29 you can specify a group name instead of a UUID. If you write "allgroups" instead, then all the groups are concerned. `
  },
  {
    cmd: 'tplocal',
    parameter: { type: 'number', min: 0, max: 256, optional: true },
    description: 'When prevented, the user cannot teleport into the same region by double-clicking, unless it is within the maximum distance if specified.'
  },
  { cmd: 'tplm', description: 'When prevented, the user cannot use a landmark, pick or any other preset location to teleport there.' },
  { cmd: 'tploc', description: 'When prevented, the user cannot use teleport to a coordinate by using the map and such.' },
  { cmd: 'tplure', description: 'When prevented, the user automatically discards any teleport offer, and the avatar who initiated the offer is notified.' },
  {
    cmd: 'sittp',
    parameter: { type: 'number', min: 0, max: 256, optional: true },
    description: 'When limited, the avatar cannot sit on a prim unless it is closer than 1.5 m. This allows cages to be secure, preventing the avatar from warping its position through the walls (unless the prim is too close). Since v2.9.20 you can specify a custom distance, if several such commands are issued, the viewer will restrict to the minimum distance of all.'
  },
  { cmd: 'standtp', description: `When this restriction is active and the avatar stands up, it is automatically teleported back to the location where it initially sat down. Please note that the "last standing location" is also stored when the restriction is issued, so this won't be a problem for grabbers and the like, that sit the victim, then move them inside a cell, which issues its restrictions, and then unsits them. In this case the avatar will stay in the cell.` },
  {
    cmd: 'accepttp',
    parameter: { type: 'avatar', optional: true },
    description: `Adding this rule will make the user automatically accept any teleport offer from the avatar which key is <UUID>, exactly like if that avatar was a Linden (no confirmation box, no message, no Cancel button). This rule does not supercede nor deprecate @tpto because the former teleports to someone, while the latter teleports to an arbitrary location. Attention : in v1.16 the UUID becomes optional, which means that @accepttp=add will force the user to accept teleport offers from anyone ! Use with caution`
  },
  {
    cmd: 'accepttprequest',
    parameter: { type: 'avatar', optional: true },
    description: `Adding this rule will make the user automatically accept any teleport request from (hence automatically send a teleport offer to) the avatar which key is <UUID>, or anyone if the UUID is omitted. `
  },
  { cmd: 'tprequest', description: `When prevented, the user cannot receive a "user wants to be teleported to your location" request from another user, and that other user receives a message if they try.` },
  { cmd: 'showinv', description: `Forces the inventory windows to close and stay closed.` },
  { cmd: 'viewnote', description: `Prevents from opening notecards but does not close the ones already open.` },
  { cmd: 'viewscript', description: `Prevents from opening scripts but does not close the ones already open.` },
  { cmd: 'viewtexture', description: `Prevents from opening textures (and snapshots) but does not close the ones already open.` },
  {
    cmd: 'edit',
    description: `When prevented from editing and opening objects, the Build & Edit window will refuse to open.`
  },
  {
    cmd: 'editobj',
    parameter: { type: 'object', optional: false },
    description: `When prevented, the Build & Edit window will refuse to open when trying to edit or open the specified object.`
  },
  { cmd: 'rez', description: `When prevented from rezzing stuff, creating and deleting objects, drag-dropping from inventory and dropping attachments will fail.` },
  { cmd: 'editworld', description: `When prevented, the user cannot edit any object that is not an attachment.` },
  { cmd: 'editattach', description: `` },
  { cmd: 'recvim', description: `When prevented, the user cannot edit any object that is not rezzed in-world and that is not a HUD.` },
  { cmd: 'share', description: `When prevented, the user cannot share anything with anyone (objects, notecards...).` },
  { cmd: 'unsit', description: `Hides the Stand up button. From v1.15 it also prevents teleporting, which was a way to stand up.` },
  { cmd: 'sit', description: `Prevents the user from sitting on anything, including with @sit:<UUID>=force.` },
  { cmd: 'addattach', description: `No attachment may be added.` },
  { cmd: 'remattach', description: `No attachment may be removed.` },
  { cmd: 'addoutfit', description: `No classic items (shirt, skin, tattoo, alpha) may be worn.` },
  { cmd: 'remoutfit', description: `No classic items (shirt, skin, tattoo, alpha) may be removed.` },
  { cmd: 'acceptpermission', description: `Forces the avatar to automatically accept attach and take control permission requests. The dialog box doesn't even show up.` },
  {
    cmd: 'touchfar',
    parameter: { type: 'number', min: 0, max: 256, optional: true },
    description: 'When prevented, the avatar is unable to touch/grab objects from more than 1.5 m away, this command makes restraints more realistic since the avatar litterally has to press against the object in order to click on it. Since v2.9.20 you can specify a custom distance, if several such commands are issued, the viewer will restrict to the minimum distance of all.'
  },
  { cmd: 'touchall', description: `When prevented, the avatar is unable to touch/grab any object and attachment. This does not apply to HUDs.` },
  { cmd: 'touchworld', description: `When prevented, the avatar is unable to touch/grab objects rezzed in-world, i.e. not attachments and HUDs.` },
  { cmd: 'touchattach', description: `When prevented, the avatar is unable to touch attachments (theirs and other avatars'), but this does not apply to HUDs.` },
  { cmd: 'touchattachself', description: `When prevented, the avatar is unable to touch their own attachments (theirs but can touch other people's), but this does not apply to HUDs.` },
  { cmd: 'touchattachother', description: `When prevented, the avatar is unable to touch other people's attachments (but they can touch their owns). This does not apply to HUDs.` },
  {
    cmd: 'touchhud',
    parameter: { type: 'object', optional: true },
    description: `When prevented, the avatar is unable to touch any HUDs. If sent with a UUID, the avatar is prevented from touching only the HUD indicated by the UUID.`
  },
  { cmd: 'interact', description: `When prevented, the avatar is unable to touch any objects, attachments, or HUDs, cannot edit or rez, and cannot sit on objects.` },
  { cmd: 'showworldmap', description: `When prevented, the avatar is unable to view the world map, and it closes if it is open when the restriction becomes active.` },
  { cmd: 'showminimap', description: `When prevented, the avatar is unable to view the mini map, and it closes if it is open when the restriction becomes active.` },
  { cmd: 'showloc', description: `When prevented, the user is unable to know where they are : the world map is hidden, the parcel and region name on the top menubar are hidden, they can't create landmarks, nor buy the land, nor see what land they have just left after a teleport, nor see the location in the About box, and even system and object messages are obfuscated if they contain the name of the region and/or the name of the parcel. However, llOwnerSay calls are not obfuscated so radars will still work (and RL commands as well).` },
  { cmd: 'shownames', description: `When prevented, the user is unable to see any name (including their own). The names don't show on the screen, the names on the chat are replaced by "dummy" names such as "Someone", "A resident", the tooltips are hidden, the pie menu is almost useless so the user can't get the profile directly etc. ` },
  { cmd: 'shownametags', description: `This restriction is the same as @shownames, except that it won't censor the chat with dummy names. However, avatars around will not have their names shown, the radar will be hidden, right-clicking on an avatar around will not disclose their names, and so on.` },
  { cmd: 'shownearby', description: `When prevented, the names in the "Nearby" tab of the "People" window are hidden, and censored in the minimap itself.` },
  { cmd: 'showhovertextall', description: `When prevented, the user is unable to read any hovertext (2D text floating above some prims).` },
  { cmd: 'showhovertexthud', description: `When prevented, the user is unable to read any hovertext showing over their HUD objects, but will be able to see the ones in-world.` },
  { cmd: 'showhovertextworld', description: `When prevented, the user is unable to read any hovertext showing over their in-world objects, but will be able to see the ones over their HUD.` },
  { cmd: 'setgroup', description: `When prevented, the user is unable to change the active group.` }
];

const missing_rule = value => !!value || 'Missing value';
const uuid_rule = value => /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/i.test(value) || 'Invalid UUID';

const rules = {
  avatar: [missing_rule, uuid_rule],
  object: [missing_rule, uuid_rule],
  number: [missing_rule, value => /^-?\d+(\.\d+)?$/.test(value) || 'Invalid number'],
  text: []
}

Vue.component('restriction-option', {
  props: ['restriction', 'option'],
  data: () => ({
    show: false,
    display: '',
    loading: false
  }),
  watch: {
    option: {
      async handler(option) {
        if (this.restriction.parameter?.type === 'avatar') {
          this.display = await NameLookup.Instance.lookup(option.value);
        } else {
          this.display = undefined;
        }
      },
      immediate: true
    }
  },
  methods: {
    async remove() {
      this.loading = true;
      await sendRLV(`@${this.restriction.cmd}:${this.option.value}=rem`);
      this.loading = false;
    }
  },
  template: `
<div>
<template>
  <v-card
    class="mx-auto my-10"
    max-width="344"
  >
    <v-card-title>
      Except
    </v-card-title>

    <v-card-text class="pb-0">
      {{ display }}
    </v-card-text>
    <v-card-text class="pt-0" v-if="display">
      {{ option.value }}
    </v-card-text>
    
    <v-card-subtitle v-if="option.another">
      Another object is {{ restriction.local ? 'also holding' : 'holding' }} this option
    </v-card-subtitle>

    <v-card-actions>
      <v-btn v-if="option.local" color="primary" text @click="remove">Remove</v-btn>
    </v-card-actions>

    <v-overlay :absolute="true" :value="loading">
      <div class="text-center">
        <v-progress-circular indeterminate color="primary"></v-progress-circular>
      </div>
    </v-overlay>
  </v-card>
</template>
</div>`
});

Vue.component('restriction', {
  props: ['restriction'],
  data: () => ({
    show: false,
    valid: false,
    input_value: '',
    loading: false,
    changeDetection: null
  }),
  computed: {
    haveMe() {
      return this.restriction.options?.some(opt => opt.value == base_data['avatar']) === true;
    }
  },
  watch: {
    restriction(restriction) {
      this.loading = false;
    }
  },
  methods: {
    async add() {
      await sendRLV(`@${this.restriction.cmd}:${this.input_value}=add`);
      this.input_value = '';
      this.$emit('exception_added', this.input_value);
      this.$emit('action');
    },
    async restrict() {
      this.loading = true;
      await sendRLV(`@${this.restriction.cmd}=add`);
      this.$emit('restricted');
      this.$emit('action');
    },
    async allow() {
      this.loading = true;
      await sendRLV(`@${this.restriction.cmd}=rem`);
      this.$emit('allowed');
      this.$emit('action');
    }
  },
  template: `
<div>
<template>
  <v-card
    v-bind:class="restriction.active ? 'red' : 'green'"
    class="mx-auto my-10"
    max-width="344"
  >
    <v-card-title>
      {{ restriction.cmd }}
    </v-card-title>

    <v-card-subtitle v-if="restriction.active && restriction.another">
      Another object is {{ restriction.local ? 'also holding' : 'holding' }} this restriction
    </v-card-subtitle>

    <v-card-text>
      <div v-if="restriction.options">
        <restriction-option v-for="item in restriction.options" :key="item.value" v-bind:restriction="restriction" v-bind:option="item"></restriction-option>
      </div>

      <v-form v-model="valid">
        <v-card class="mx-auto my-10" max-width="344" v-if="restriction.parameter">
          <v-card-title>Add exception</v-card-title>
      
          <v-card-text>
            <v-text-field
              :label="restriction.parameter.type"
              :rules="rules[restriction.parameter.type]"
              v-model.value="input_value"></v-text-field>
          </v-card-text>
      
          <v-card-actions>
            <v-btn color="primary" text v-bind:disabled="!valid" @click="add">Add</v-btn>
            <v-btn color="primary" text @click="input_value = base_data['avatar']" v-bind:disabled="haveMe">Me</v-btn>
          </v-card-actions>
        </v-card>
      </v-form>
    </v-card-text>

    <v-card-actions>
      <template v-if="restriction.parameter?.optional !== false">
        <v-btn
          v-if="restriction.local"
          color="primary"
          text
          @click="allow"
        >
          Allow
        </v-btn>

        <v-btn
          v-if="!restriction.local"
          color="primary"
          text
          @click="restrict"
        >
          Restrict
        </v-btn>
      </template>

      <v-spacer></v-spacer>

      <v-btn
        icon
        v-if="restriction.description"
        @click="show = !show"
      >
        <v-icon>{{ show ? 'mdi-chevron-up' : 'mdi-chevron-down' }}</v-icon>
      </v-btn>
    </v-card-actions>

    <v-expand-transition v-if="restriction.description">
      <div v-show="show">
        <v-divider></v-divider>

        <v-card-text>
          {{ restriction.description }}
        </v-card-text>
      </div>
    </v-expand-transition>
    <v-overlay :absolute="true" :value="loading">
      <div class="text-center">
        <v-progress-circular indeterminate color="primary"></v-progress-circular>
      </div>
    </v-overlay>
  </v-card>
</template>
</div>`
});

var app = new Vue({
  el: '#app',
  vuetify: new Vuetify(),
  data: () => ({
    target: '',
    show_only_active_restrictions: false,
    restrictions: [],
    avatar_key: '',
    avatar_name: ''
  }),
  async created() {
    this.avatar_key = base_data['avatar'];
    this.avatar_name = await NameLookup.Instance.lookup(this.avatar_key);
  },
  mounted() {
    this.loadRestrictions();

    document.addEventListener('RLV', this.onRLVEvent);
  },
  unmounted() {
    document.removeEventListener('RLV', this.onRLVEvent);
  },
  methods: {
    async clear() {
      await sendRLV(`@clear`);
    },
    async onRLVEvent(event) {
      await this.loadRestrictions();
    },
    async loadRestrictions() {
      // let cached_restrictions = new Cache('CachedRestrinctions');
      // let loaded_restrictions = await cached_restrictions.getOrFetch('restrictions', async () => await getRLVRestrictions());
      let loaded_restrictions = await getRLVRestrictions();

      let restrictions = managed_restrictions.map(restriction => ({ ...restriction, ...loaded_restrictions[restriction.cmd] }));

      this.restrictions = restrictions;

      this.$emit('freshrestrictionsinfo');
    }
  }
});
