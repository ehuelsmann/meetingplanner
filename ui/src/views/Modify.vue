<template>
    <div id="create" >
        <div id="attendees">
            <table>
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Role</th>
                    </tr>
                </thead>
                <tbody v-if="attendees" >
                    <tr v-for="attendee in attendees"
                        :key="attendee.key"
                        :class="(attendee.key === editingAttendee) ? 'editing':'presenting'" >
                        <td>{{ attendee.name }} </td>
                        <td>{{ attendee.organizer ? "Organizer" : "" }}</td>
                    </tr>
                </tbody>
                <tfoot>
                    <tr>
                        <td>
                            <input type="text" name="name" id="name-input" size="20" v-model="name">
                        </td>
                        <td></td>
                        <td>
                            <button @click.prevent="btnAddAttendee"
                                    :disabled="name.length == 0">Add</button>
                        </td>
                    </tr>
                </tfoot>
            </table>
        </div>
        <div id="dates" v-if="dates">
            <table>
                <thead>
                    <tr>
                        <th>Date</th>
                        <th>Time</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="date in dates"
                        :key="date.key">
                        <td>{{ date.date }}</td>
                        <td>{{ date.time }}</td>
                    </tr>
                </tbody>
                <tfoot>
                    <tr>
                        <td>
                            <input type="text" name="date" id="date-input"
                                   size="20" v-model="date">
                        </td>
                        <td>
                            <input type="text" name="time" id="time-input"
                                   size="10" v-model="time">
                        </td>
                        <td>
                            <button id="date-add-btn"
                                    :disabled="date.length == 0"
                                    @click.prevent="btnAddDate">Add</button>
                        </td>
                    </tr>
                </tfoot>
            </table>
        </div>
    </div>
</template>

<script>
import { mapActions, mapState } from 'vuex';

export default {
    data() {
        return {
            name: "",
            date: "",
            time: ""
        }
    },
    props: {
        editingAttendee: String,
        event: String
    },
    computed: {
        ...mapState([
            'attendees',
            'dates'
        ])
    },
    methods: {
        ...mapActions([
            'addAttendee',
            'addDate',
            'getEventData'
        ]),
        async btnAddAttendee() {
            this.addAttendee({ name: this.name })
                .then(() => {
                    this.name = "";
                });
        },
        async btnAddDate() {
            this.addDate({date: this.date, time: this.time})
                .then(() => {
                    this.date = "";
                    this.time = "";
                });
        },
        fetchData() {
            this.getEventData({
                event: this.event,
                editor: this.editingAttendee
            });
        }
    },
    created() {
        this.fetchData();
    }
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

#date-entry {
    display: inline-grid;
    grid-template-columns: auto auto;
    grid-gap: 4px;
}

#date-add-btn {
    display: block;
    float: right;
}

button {
    margin: 0;
}

</style>
