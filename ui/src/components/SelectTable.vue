<template>
    <div class="hello">
        <h1>Select availability</h1>
        <p>
            Select your available dates
        </p>
        <table>
            <thead>
                <tr>
                    <th>Name</th>
                    <th>Role</th>
                    <th v-for="d in dates" :key="d.key">
                        {{ d.date }}
                        <template v-if="d.time">
                            <br/><span class="time">{{ d.time }}</span>
                        </template>
                    </th>
                </tr>
            </thead>
            <tbody v-if="selections">
                <template v-for="attendee in attendees"
                          :key="attendee.key" >
                    <SelectRow :attendee="attendee"
                               :selections="selections[attendee.key]"
                               :class="(attendee.key === editingAttendee) ? 'editing':'presenting'" />
                </template>
            </tbody>
            <tfoot>
                <tr class="button-area">
                    <td :colspan="2+dates.length">
                        <button :disabled="!changed"
                                type="button"
                                @click.prevent="saveAttendance">Submit</button>
                    </td>
                </tr>
            </tfoot>
        </table>
    </div>
</template>

<script>
import SelectRow from '@/components/SelectRow.vue';
import { mapActions, mapGetters, mapState } from 'vuex';

export default {
    name: 'SelectTable',
    components: {
        SelectRow
    },
    computed: {
        ...mapState([
            'attendees',
            'dates',
            'selections'
        ]),
        ...mapGetters([
            'changed',
            'editingAttendee'
        ]),
    },
    methods: {
        ...mapActions([
            'saveAttendance'
        ])
    }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
h3 {
    margin: 40px 0 0;
}
ul {
    list-style-type: none;
    padding: 0;
}
li {
    display: inline-block;
    margin: 0 10px;
}
a {
    color: #42b983;
}
table {
    margin-left: auto;
    margin-right: auto;
}
table thead {
    background-color: white;
    position: sticky;
    top: 0;
    bottom: 0;
}
tr th:first-child {
    text-align: left;
}
tr th, tr td {
    text-align: center;
    vertical-align: bottom;
}
th, td {
    padding-left: 1em;
    padding-right: 1em;
}
.button-area {
    background-color: white;
    position: sticky;
    bottom: 0;
}
span.time {
    font-weight: normal;
}
</style>
