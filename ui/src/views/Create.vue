<template>
    <div >
        <h1>Create a new planner</h1>
        <p>Enter the data of the meeting organizer</p>
        <div>
            <label for="name-input">Name </label>
            <input v-model="name" name="name" id="name-input">
        </div>
        <button @click.prevent="createEvent" >Create</button>
    </div>
</template>

<script>
import { mapActions } from 'vuex';

export default {
    data() {
        return {
            name: ""
        }
    },
    methods: {
        ...mapActions([
            'createEventData',
        ]),
        async createEvent() {
            this.createEventData({ attendees: [ { name: this.name } ] })
                .then(eventData => {
                    this.$router.push(
                        `/events/${eventData.event}/modify/${eventData.attendees[0].key}`
                    )
                });
        },
    },
}
</script>

<style scoped>
.entry {
    text-align: left;
    justfy-content: left;
}
#create {
    display: grid;
    grid-template-columns: auto auto;
}
#attendees {
    margin-left: auto;
    margin-right: auto;
}
#dates {
    margin-left: auto;
    margin-right: auto;
}
tr:hover {
    background-color: #eee;
}
</style>
