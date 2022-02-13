<template>
    <div id="updates" v-show="showingUpdates">{{ serverStatus }}</div>
    <div id="nav">|
        <template v-if="event">
            <router-link
                :to="`/events/${event}/avail/${editingAttendee}`">Availability</router-link> |
            <router-link
                :to="`/events/${event}/modify/${editingAttendee}`">Modify</router-link> |
        </template>
        <router-link to="/events">Create new</router-link> |
        <router-link to="/about">About</router-link> |
    </div>
    <router-view/>
</template>

<script>
import { mapGetters, mapState } from 'vuex';
import { debounce } from 'lodash';

export default {
    data() {
        return {
            showingUpdates: false
        };
    },
    computed: {
        ...mapState([
            'event',
            'serverStatus',
        ]),
        ...mapGetters([
            'editingAttendee'
        ])
    },
    watch: {
        serverStatus() {
            this.showUpdates();
        }
    },
    created() {
        this.showUpdates = function() {
            this.showingUpdates = true;
            this.hideUpdates();
        };
        this.hideUpdates = debounce(
            () => { this.showingUpdates = false },
            1500);
    }
}

</script>

<style>
#app {
    font-family: Avenir, Helvetica, Arial, sans-serif;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    text-align: center;
    color: #2c3e50;
}

#nav {
    padding: 30px;
}

#nav a {
    font-weight: bold;
    color: #2c3e50;
}

#nav a.router-link-exact-active {
    color: #42b983;
}

#updates {
    background-color: #009b00;
    height: 2em;
    position: fixed;
    top: 20px;
    color: white;
    padding-top: 0.5em;
    border-radius: 6px;
    min-width: 10ex;
    padding-bottom: 0.5em;
    padding-left: 3ex;
    padding-right: 3ex;
    text-align: center;
    box-sizing: border-box;
    right: 10%;
    font-weight: bold;
}

.editing {
    background-color: lightyellow;
}
.presenting {
    background-color: #e8e8e8;
    color: grey;
    font-weight: normal;
}
button {
    background-color: #66f;
    color: white;
    font-weight: bold;
    border: 2px solid #66f;
    padding: 1ex 1em;
    border-radius: 4px;
    margin: 1em;
    text-shadow: 2px 2px #444;
    cursor: pointer;
    position: sticky;
    left: 0;
    right: 0;
}
button:hover {
    border: 2px solid #004;
    box-shadow: 2px 2px 4px #444;
}
button:disabled, button:disabled:hover {
    background-color: #ccc;
    color: #999;
    text-shadow: none;
    border: 2px solid #ccc;
    box-shadow: none;
    cursor: inherit;
}
</style>
